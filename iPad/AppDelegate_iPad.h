//
//  AppDelegate_iPad.h
//  SocialNetworkClient
//
//  Created by Damien DeVille on 1/22/11.
//  Copyright 2011 Snappy Code. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DDiPadViewController ;

@interface AppDelegate_iPad : NSObject <UIApplicationDelegate>
{
	UIWindow *window ;
	
	IBOutlet DDiPadViewController *viewController ;
}

@property (nonatomic,retain) IBOutlet UIWindow *window ;
@property (nonatomic,retain) IBOutlet DDiPadViewController *viewController ;

@end

