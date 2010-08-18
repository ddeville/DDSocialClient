//
//  DDSocialNetworkClientAppDelegate.h
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 7/27/10.
//  Copyright Damien DeVille 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DDSocialNetworkTestViewController ;

@interface DDSocialNetworkClientAppDelegate : NSObject <UIApplicationDelegate>
{
	UIWindow *window ;
	IBOutlet DDSocialNetworkTestViewController *viewController ;
}

@property (nonatomic, retain) IBOutlet UIWindow *window ;
@property (nonatomic, retain) IBOutlet DDSocialNetworkTestViewController *viewController ;

@end
