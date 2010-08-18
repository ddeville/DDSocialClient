//
//  DDSocialNetworkClientAppDelegate.m
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 7/27/10.
//  Copyright Damien DeVille 2010. All rights reserved.
//

#import "DDSocialNetworkClientAppDelegate.h"
#import "DDSocialNetworkTestViewController.h"



@implementation DDSocialNetworkClientAppDelegate

@synthesize window ;
@synthesize viewController ;


#pragma mark -
#pragma mark Application lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[window addSubview: viewController.view] ;
	[window makeKeyAndVisible] ;
	
	return YES ;
}



- (void)applicationWillResignActive:(UIApplication *)application
{
	
}


- (void)applicationDidEnterBackground:(UIApplication *)application
{
	
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
	
}


- (void)applicationDidBecomeActive:(UIApplication *)application
{
	
}


- (void)applicationWillTerminate:(UIApplication *)application
{
	
}





#pragma mark -
#pragma mark Memory management

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	
}


- (void)dealloc
{
	[viewController release] ;
	[window release] ;
	
	[super dealloc] ;
}


@end
