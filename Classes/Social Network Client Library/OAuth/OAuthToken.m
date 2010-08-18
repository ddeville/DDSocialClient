//
//  OAuthToken.m
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 8/5/10.
//  Copyright 2010 Damien DeVille. All rights reserved.
//

#import "OAuthToken.h"

@interface OAuthToken (Private)

+ (NSString *)userDefaultsSignature:(NSString *)aService ;

@end




@implementation OAuthToken

@synthesize service ;
@synthesize key ;
@synthesize secret ;
@synthesize creationDate ;
@synthesize duration ;
@synthesize userID ;


#pragma mark -
#pragma mark Init methods

+ (id)tokenForService:(NSString *)myService
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults] ;
	NSString *sig = [OAuthToken userDefaultsSignature: myService] ;
	
	NSString *newKey = nil ;
	NSString *newSecret = nil ;
	if (!(newKey = [userDefaults objectForKey: [sig stringByAppendingString: @"key"]]))
		return nil ;
	if (!(newSecret = [userDefaults objectForKey: [sig stringByAppendingString: @"secret"]]))
		return nil ;
	
	NSDate *newCreationDate = [userDefaults objectForKey: [sig stringByAppendingString: @"creationDate"]] ;
	NSNumber *newDuration = [userDefaults objectForKey: [sig stringByAppendingString: @"duration"]] ;
	NSString *newUserID = [userDefaults objectForKey: [sig stringByAppendingString: @"userID"]] ;
	
	OAuthToken *newToken = [[OAuthToken alloc] initWithService: myService
														andKey: newKey
													 andSecret: newSecret
											   andCreationDate: newCreationDate
												   andDuration: newDuration
													 andUserID: newUserID] ;
	[newToken autorelease] ;
	return newToken ;
}



- (id)initWithService:(NSString *)myService andKey:(NSString *)myKey andSecret:(NSString *)mySecret
{
	return [self initWithService: myService andKey: myKey andSecret: mySecret andCreationDate: nil andDuration: nil andUserID: nil] ;
}



- (id)initWithService:(NSString *)myService andKey:(NSString *)myKey andSecret:(NSString *)mySecret andCreationDate:(NSDate *)myCreationDate andDuration:(NSNumber *)myDuration andUserID:(NSString *)myUserID
{
	if (!myKey || !mySecret)
		return nil ;
	
	if (self = [super init])
	{
		[self setService: myService] ;
		[self setKey: myKey] ;
		[self setSecret: mySecret] ;
		[self setCreationDate: myCreationDate] ;
		[self setDuration: myDuration] ;
		[self setUserID: myUserID] ;
	}
	return self ;
}









#pragma mark -
#pragma mark Token comparison and validity methods

- (BOOL)isValid
{
	if ((key && [key length]) && (secret && [secret length]))
		return YES ;
	return NO ;
}



- (BOOL)hasExpired
{
	if (creationDate && duration)
	{
#if RUNNING_IOS4_0_OR_GREATER
		// for iOS 4.0
		if ([[creationDate dateByAddingTimeInterval: [duration intValue]] compare: [NSDate date]] == NSOrderedAscending)
			return YES ;
#else
		// prior to iOS 4.0 --> deprecated on iOS 4.0
		if ([[creationDate addTimeInterval: [duration intValue]] compare: [NSDate date]] == NSOrderedAscending)
			return YES ;
#endif
	}
	return NO ;
}



- (BOOL)isEqualToToken:(OAuthToken *)anotherToken
{
	if ([self.key isEqualToString: anotherToken.key] && [self.secret isEqualToString: anotherToken.secret])
	{
		if (self.creationDate)
		{
			if (![self.creationDate isEqualToDate: anotherToken.creationDate])
				return NO ;
		}
		if (self.duration)
		{
			if (![self.duration isEqualToNumber: anotherToken.duration])
				return NO ;
		}
		if (self.userID)
		{
			if (![self.userID isEqualToString: anotherToken.userID])
				return NO ;
		}
		return YES ;
	}
	return NO ;
}









#pragma mark -
#pragma mark User defaults related methods

- (void)storeToUserDefaults
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults] ;
	NSString *sig = [OAuthToken userDefaultsSignature: service] ;
	
	if (key)
		[userDefaults setObject: key forKey: [sig stringByAppendingString: @"key"]] ;
	if (secret)
		[userDefaults setObject: secret forKey: [sig stringByAppendingString: @"secret"]] ;
	if (creationDate)
		[userDefaults setObject: creationDate forKey: [sig stringByAppendingString: @"creationDate"]] ;
	if (duration)
		[userDefaults setObject: duration forKey: [sig stringByAppendingString: @"duration"]] ;
	if (userID)
		[userDefaults setObject: userID forKey: [sig stringByAppendingString: @"userID"]] ;
	
	[userDefaults synchronize] ;
}



+ (void)deleteTokenFromUserDefaultsForService:(NSString *)aService
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults] ;
	NSString *sig = [OAuthToken userDefaultsSignature: aService] ;
	
	[userDefaults removeObjectForKey: [sig stringByAppendingString: @"key"]] ;
	[userDefaults removeObjectForKey: [sig stringByAppendingString: @"secret"]] ;
	[userDefaults removeObjectForKey: [sig stringByAppendingString: @"creationDate"]] ;
	[userDefaults removeObjectForKey: [sig stringByAppendingString: @"duration"]] ;
	[userDefaults removeObjectForKey: [sig stringByAppendingString: @"userID"]] ;
	
	[userDefaults synchronize] ;
}



+ (NSString *)userDefaultsSignature:(NSString *)aService ;
{
	NSString *appIdentifier = [[NSBundle mainBundle] bundleIdentifier] ;
	appIdentifier = [appIdentifier stringByReplacingOccurrencesOfString: @"." withString: @"-"] ;
	
	return [NSString stringWithFormat:  @"%@-%@-", appIdentifier, aService] ;
}










#pragma mark -
#pragma mark Memory management methods

- (void)dealloc
{
	self.key = nil ;
	self.secret = nil ;
	self.creationDate = nil ;
	self.duration = nil ;
	self.userID = nil ;
	[super dealloc] ;
}


@end
