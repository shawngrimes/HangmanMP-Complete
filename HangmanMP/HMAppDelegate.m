//
//  HMAppDelegate.m
//  HangmanMP
//
//  Created by Shawn Grimes on 10/29/11.
//  Copyright (c) 2011 Shawn's Bits, LLC. All rights reserved.
//

#import "HMAppDelegate.h"
#import <GameKit/GameKit.h>

@implementation HMAppDelegate

@synthesize window = _window;
@synthesize localPlayer;

+(BOOL) isGameCenterAvailable
{
    // Check for presence of GKLocalPlayer class.
    BOOL localPlayerClassAvailable = (NSClassFromString(@"GKLocalPlayer")) != nil;
    
    // The device must be running iOS 4.1 or later.
    NSString *reqSysVer = @"4.1";
    NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
    BOOL osVersionSupported = ([currSysVer compare:reqSysVer
                                           options:NSNumericSearch] != NSOrderedAscending);
    
    return (localPlayerClassAvailable && osVersionSupported);
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    if([HMAppDelegate isGameCenterAvailable]){
        //If GameCenter is available, let's authenticate the user
        GKLocalPlayer *_localPlayer=[GKLocalPlayer localPlayer];
        [_localPlayer authenticateWithCompletionHandler:^(NSError *error) {
            if(_localPlayer.isAuthenticated){
                self.localPlayer=_localPlayer;
            }
        }];
    }
    
    //Report old scores
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *scoreFilePath = [NSString stringWithFormat:@"%@/scores.plist",[paths objectAtIndex:0]];
    NSMutableDictionary *scoreDictionary=[NSMutableDictionary dictionaryWithContentsOfFile:scoreFilePath];
    
    for (NSDate *dateID in [scoreDictionary allKeys]) {
        NSLog(@"Reporting old score: %@", dateID);
        GKScore *scoreToReport=(GKScore *)[scoreDictionary objectForKey:dateID];
        [scoreToReport reportScoreWithCompletionHandler:^(NSError *error) {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
            NSString *scoreFilePath = [NSString stringWithFormat:@"%@/scores.plist",[paths objectAtIndex:0]];
            NSMutableDictionary *scoreDictionary=[NSMutableDictionary dictionaryWithContentsOfFile:scoreFilePath];
            
            if (error != nil)
            {
                //There was an error so we need to save the score locally and resubmit later
                [scoreDictionary setValue:scoreToReport forKey:scoreToReport.playerID];
                [scoreDictionary writeToFile:scoreFilePath atomically:YES];
            }
        }]; 

    }
    
    //Report saved achievements
    NSString *achievementFilePath = [NSString stringWithFormat:@"%@/achievements.plist",[paths objectAtIndex:0]];
    NSMutableDictionary *achievementDictionary=[NSMutableDictionary dictionaryWithContentsOfFile:achievementFilePath];
    for (id achievement in [achievementDictionary allKeys]){
        GKAchievement *achievementToReport=(GKAchievement *)[achievementDictionary objectForKey:achievement];
        [achievementToReport reportAchievementWithCompletionHandler:^(NSError *error)
         {
             if (error != nil)
             {
                 //There was an error so we need to save the achievement locally and resubmit later
                 NSLog(@"Saving achievement for later");
                 NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
                 NSString *achievementFilePath = [NSString stringWithFormat:@"%@/achievements.plist",[paths objectAtIndex:0]];
                 NSMutableDictionary *achievementDictionary=[NSMutableDictionary dictionaryWithContentsOfFile:achievementFilePath];
                 
                 [achievementDictionary setValue:achievementToReport forKey:achievement];
                 [achievementDictionary writeToFile:achievementFilePath atomically:YES];
             }else{
                 NSLog(@"Achievement reported");
             }
         }];

    }
    
    
    return YES;
}


							
- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

@end
