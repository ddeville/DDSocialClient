//
//  OAuthToken.h
//  SocialNetworkClient
//
//  Created by Damien DeVille on 8/5/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import <Foundation/Foundation.h>

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

@property (nonatomic,copy) NSString *service ;
@property (nonatomic,copy) NSString *key ;
@property (nonatomic,copy) NSString *secret ;
@property (nonatomic,retain) NSDate *creationDate ;
@property (nonatomic,retain) NSNumber *duration ;
@property (nonatomic,copy) NSString *userID ;

+ (id)tokenForService:(NSString *)aService ;
- (id)initWithService:(NSString *)aService andKey:(NSString *)aKey andSecret:(NSString *)aSecret ;
- (id)initWithService:(NSString *)aService andKey:(NSString *)aKey andSecret:(NSString *)aSecret andCreationDate:(NSDate *)aCreationDate andDuration:(NSNumber *)aDuration andUserID:(NSString *)aUserID ;

- (BOOL)isValid ;
- (BOOL)hasExpired ;
- (BOOL)isEqualToToken:(OAuthToken *)anotherToken ;

- (void)store ;
+ (void)deleteTokenForService:(NSString *)aService ;

@end
