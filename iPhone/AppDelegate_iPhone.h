//
//  AppDelegate_iPhone.h
//  SocialNetworkClient
//
//  Created by Damien DeVille on 1/22/11.
//  Copyright 2011 Snappy Code. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DDiPhoneViewController ;

@interface AppDelegate_iPhone : NSObject <UIApplicationDelegate>
{
	UIWindow *window ;
	
	IBOutlet DDiPhoneViewController *viewController ;
}

@property (nonatomic,retain) IBOutlet UIWindow *window ;
@property (nonatomic,retain) IBOutlet DDiPhoneViewController *viewController ;

@end

