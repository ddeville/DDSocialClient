//
//  OAuthToken.h
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 8/5/10.
//  Copyright 2010 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifndef kCFCoreFoundationVersionNumber_iPhoneOS_4_0
#define kCFCoreFoundationVersionNumber_iPhoneOS_4_0 550.32
#endif


@interface OAuthToken : NSObject
{
	// service name, required for saving and retrieving a OAuthToken
	NSString *service ;
	
	// the following 2 are required for forming a OAuthToken
	NSString *key ;
	NSString *secret ;
	
	// optional parameters for a OAuthToken
	NSDate *creationDate ;
	NSNumber *duration ;
	
	// optional additional parameters
	NSString *userID ;
}

@property (retain) NSString *service ;
@property (retain) NSString *key ;
@property (retain) NSString *secret ;
@property (retain) NSDate *creationDate ;
@property (retain) NSNumber *duration ;
@property (retain) NSString *userID ;


+ (id)tokenForService:(NSString *)myService ;
- (id)initWithService:(NSString *)myService andKey:(NSString *)myKey andSecret:(NSString *)mySecret ;
- (id)initWithService:(NSString *)myService andKey:(NSString *)myKey andSecret:(NSString *)mySecret andCreationDate:(NSDate *)myCreationDate andDuration:(NSNumber *)myDuration andUserID:(NSString *)myUserID ;

- (BOOL)isValid ;
- (BOOL)hasExpired ;
- (BOOL)isEqualToToken:(OAuthToken *)anotherToken ;

- (void)storeToUserDefaults ;
+ (void)deleteTokenFromUserDefaultsForService:(NSString *)aService ;


@end
