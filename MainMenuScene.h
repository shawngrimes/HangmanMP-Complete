//
//  MainMenuScene.h
//  HangmanMP
//
//  Created by Shawn Grimes on 10/29/11.
//  Copyright (c) 2011 Shawn's Bits, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <GameKit/GameKit.h>

@interface MainMenuScene : UIViewController <GKLeaderboardViewControllerDelegate, GKAchievementViewControllerDelegate,GKMatchmakerViewControllerDelegate>

- (IBAction)actionShowHighScores:(id)sender;
- (IBAction)actionShowAchievements:(id)sender;
- (IBAction)actionHostMatch:(id)sender;

@end
