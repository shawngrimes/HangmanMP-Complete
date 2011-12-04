//
//  HMAppDelegate.h
//  HangmanMP
//
//  Created by Shawn Grimes on 10/29/11.
//  Copyright (c) 2011 Shawn's Bits, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class GKLocalPlayer;

@interface HMAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property(strong, nonatomic) GKLocalPlayer *localPlayer;


+(BOOL) isGameCenterAvailable;

@end
