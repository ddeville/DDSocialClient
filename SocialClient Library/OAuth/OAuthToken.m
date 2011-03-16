//
//  OAuthToken.m
//  SocialNetworkClient
//
//  Created by Damien DeVille on 8/5/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import "OAuthToken.h"

@interface OAuthToken (Private)

+ (NSString *)userDefaultsSignature:(NSString *)aService ;

- (BOOL)storeToKeychainWithAppName:(NSString *)name andServiceName:(NSString *)provider ;
+ (BOOL)removeFromKeychainWithAppName:(NSString *)name andServiceName:(NSString *)provider ;
+ (NSDictionary *)getTokenFromKeychainWithAppName:(NSString *)name andServiceName:(NSString *)provider ;

@end


@implementation OAuthToken

@synthesize service ;
@synthesize key ;
@synthesize secret ;
@synthesize creationDate ;
@synthesize duration ;
@synthesize userID ;

+ (id)tokenForService:(NSString *)aService
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults] ;
	NSString *sig = [OAuthToken userDefaultsSignature: aService] ;
	NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleName"] ;
	
	NSString *newKey = nil ;
	NSString *newSecret = nil ;
	
	// fetch the token from the keychain
	NSDictionary *result = [OAuthToken getTokenFromKeychainWithAppName: appName andServiceName: sig] ;
	if (result == nil)
		return nil ;
	if (!(newKey = (NSString *)[result objectForKey: (NSString *)kSecAttrAccount]))
		return nil ;
	if (!(newSecret = (NSString *)[result objectForKey: (NSString *)kSecAttrGeneric]))
		return nil ;
	
	// fetch the other data from the user defaults
	NSDate *newCreationDate = [userDefaults objectForKey: [sig stringByAppendingString: @"creationDate"]] ;
	NSNumber *newDuration = [userDefaults objectForKey: [sig stringByAppendingString: @"duration"]] ;
	NSString *newUserID = [userDefaults objectForKey: [sig stringByAppendingString: @"userID"]] ;
	
	// create the token
	OAuthToken *newToken = [[OAuthToken alloc] initWithService: aService
														andKey: newKey
													 andSecret: newSecret
											   andCreationDate: newCreationDate
												   andDuration: newDuration
													 andUserID: newUserID] ;
	[newToken autorelease] ;
	return newToken ;
}

- (id)initWithService:(NSString *)aService andKey:(NSString *)aKey andSecret:(NSString *)aSecret
{
	return [self initWithService: aService andKey: aKey andSecret: aSecret andCreationDate: nil andDuration: nil andUserID: nil] ;
}

- (id)initWithService:(NSString *)aService andKey:(NSString *)aKey andSecret:(NSString *)aSecret andCreationDate:(NSDate *)aCreationDate andDuration:(NSNumber *)aDuration andUserID:(NSString *)aUserID
{
	if (aKey == nil || aSecret == nil)
		return nil ;
	
	if ((self = [super init]))
	{
		[self setService: aService] ;
		[self setKey: aKey] ;
		[self setSecret: aSecret] ;
		[self setCreationDate: aCreationDate] ;
		[self setDuration: aDuration] ;
		[self setUserID: aUserID] ;
	}
	return self ;
}

- (void)dealloc
{
	[key release], key = nil ;
	[secret release], secret = nil ;
	[creationDate release], creationDate = nil ;
	[duration release], duration = nil ;
	[userID release], userID = nil ;
	
	[super dealloc] ;
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
		if ([[NSDate dateWithTimeInterval: [duration floatValue] sinceDate: creationDate] compare: [NSDate date]] == NSOrderedAscending)
			return YES ;
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

- (void)store
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults] ;
	NSString *sig = [OAuthToken userDefaultsSignature: service] ;
	NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleName"] ;
	
	// store the token key and secret to the keychain
	if (key || secret)
		[self storeToKeychainWithAppName: appName andServiceName: sig] ;
	
	// store the other data to the user defaults
	if (creationDate)
		[userDefaults setObject: creationDate forKey: [sig stringByAppendingString: @"creationDate"]] ;
	if (duration)
		[userDefaults setObject: duration forKey: [sig stringByAppendingString: @"duration"]] ;
	if (userID)
		[userDefaults setObject: userID forKey: [sig stringByAppendingString: @"userID"]] ;
	
	[userDefaults synchronize] ;
}

+ (void)deleteTokenForService:(NSString *)aService
{
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults] ;
	NSString *sig = [OAuthToken userDefaultsSignature: aService] ;
	NSString *appName = [[[NSBundle mainBundle] infoDictionary] objectForKey: @"CFBundleName"] ;
	
	// remove the token key and secret from the keychain
	[OAuthToken removeFromKeychainWithAppName: appName andServiceName: sig] ;
	
	// remove the other data from the user defaults
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

+ (NSString *)serviceNameForAppName:(NSString *)name andProvider:(NSString *)provider
{
	NSString *serviceName = [NSString stringWithFormat: @"%@::OAuth::%@", name, provider] ;
	serviceName = [serviceName stringByReplacingOccurrencesOfString: @" " withString: @"-"] ;
	
	return serviceName ;
}



#pragma mark -
#pragma mark Keychain related methods

- (BOOL)storeToKeychainWithAppName:(NSString *)name andServiceName:(NSString *)provider
{
	NSString *serviceName = [OAuthToken serviceNameForAppName: name andProvider: provider] ;
	NSString *keychainLabel = @"OAuth Access Token" ;
	
	OSStatus status ;
	
	// remove the old token key and secret from the keychain
	NSArray *keys = [NSArray arrayWithObjects: (id)kSecClass, kSecAttrService, nil] ;
	NSArray *objects = [NSArray arrayWithObjects: (id)kSecClassGenericPassword, serviceName, nil] ;
	NSDictionary *query = [NSDictionary dictionaryWithObjects: objects forKeys: keys] ;
	status = SecItemDelete((CFDictionaryRef)query) ;
	
	if (status != noErr)
		return NO ;
	
	// add the token key and secret to the keychain
	keys = [NSArray arrayWithObjects: (id)kSecClass, kSecAttrService, kSecAttrLabel, kSecAttrAccount, kSecAttrGeneric, nil] ;
	objects = [NSArray arrayWithObjects: (id)kSecClassGenericPassword, serviceName, keychainLabel, self.key, self.secret, nil] ;
	query = [NSDictionary dictionaryWithObjects: objects forKeys: keys] ;
	status = SecItemAdd((CFDictionaryRef)query, NULL) ;
	
	return (status == noErr) ;
}

+ (BOOL)removeFromKeychainWithAppName:(NSString *)name andServiceName:(NSString *)provider
{
	NSString *serviceName = [OAuthToken serviceNameForAppName: name andProvider: provider] ;
	
	OSStatus status ;
	
	// remove the token key and secret from the keychain
	NSArray *keys = [NSArray arrayWithObjects: (id)kSecClass, kSecAttrService, nil] ;
	NSArray *objects = [NSArray arrayWithObjects: (id)kSecClassGenericPassword, serviceName, nil] ;
	NSDictionary *query = [NSDictionary dictionaryWithObjects: objects forKeys: keys] ;
	status = SecItemDelete((CFDictionaryRef)query) ;
	
	return (status == noErr) ;
}

+ (NSDictionary *)getTokenFromKeychainWithAppName:(NSString *)name andServiceName:(NSString *)provider
{
	NSString *serviceName = [OAuthToken serviceNameForAppName: name andProvider: provider] ;
	
	OSStatus status ;
	
	// get the token key and secret from the keychain
	NSArray *keys = [NSArray arrayWithObjects: (id)kSecClass, kSecAttrService, kSecReturnAttributes, nil] ;
	NSArray *objects = [NSArray arrayWithObjects: (id)kSecClassGenericPassword, serviceName, kCFBooleanTrue, nil] ;
	NSDictionary *query = [NSDictionary dictionaryWithObjects: objects forKeys: keys] ;
	
	NSMutableDictionary *result = nil ;
	status = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&result) ;
	
	if (status != noErr)
		return nil ;
	
	return result ;
}

@end
