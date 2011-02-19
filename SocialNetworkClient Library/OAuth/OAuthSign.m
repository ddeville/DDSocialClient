//
//  OAuthSign.m
//  SocialNetworkClient
//
//  Created by Damien DeVille on 8/5/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import "OAuthSign.h"
#import "NSString+PercentEncode.h"
#import "NSData+Base64Encode.h"

#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>

@implementation OAuthSign

+ (NSString *)getOAuthSignatureForMethod:(NSString *)method URL:(NSString *)URL callback:(NSString *)callback consumerKey:(NSString *)consumerKey consumerKeySecret:(NSString *)consumerKeySecret token:(NSString *)token tokenSecret:(NSString *)tokenSecret verifier:(NSString *)verifier postParameters:(NSDictionary *)postParameters headerStyle:(BOOL)headerStyle
{
	// Check whether the URL contains URL query parameters
	NSUInteger queryParametersLocation = [URL rangeOfString: @"?"].location ;
	NSArray *queryParameters = nil ;
	
	// if the URL has query parameters
	if (queryParametersLocation != NSNotFound)
	{
		// get the parameters part of the URL
		NSString *queryString = [URL substringFromIndex: queryParametersLocation] ;
		
		// get the name=value parameters
		queryParameters = [queryString componentsSeparatedByString: @"&"] ;
	}
	
	NSMutableDictionary *parameters = [NSMutableDictionary dictionary] ;
	NSMutableDictionary *encodedParameters = [NSMutableDictionary dictionary] ;
	
	// get the query parameters
	for (NSString *subString in queryParameters)
	{
		NSArray *parameter = [subString componentsSeparatedByString: @"="] ;
		if ([parameter count] > 1)
		{
			NSString *name = [[parameter objectAtIndex: 0] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ;
			NSString *value = [[parameter objectAtIndex: 1] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ;
			[parameters setObject: value forKey: name] ;
		}
	}
	
	// get the eventual POST parameters
	if (postParameters)
		[parameters addEntriesFromDictionary: postParameters] ;
	
	// Assign values to the OAuth protocol parameters (some are optional)
	
	// OAuth consumer key
	if (consumerKey)
		[parameters setObject: consumerKey forKey: @"oauth_consumer_key"] ;
	
	// OAuth token
	if (token)
		[parameters setObject: token forKey: @"oauth_token"] ;
	
	// OAuth callback
	if (callback)
		[parameters setObject: callback forKey: @"oauth_callback"] ;
	
	// OAuth verifier
	if (verifier)
		[parameters setObject: verifier forKey: @"oauth_verifier"] ;
	
	// OAuth signature method
	[parameters setObject: @"HMAC-SHA1" forKey: @"oauth_signature_method"] ;
	
	// OAuth time stamp
	NSString *timeStamp = [NSString stringWithFormat: @"%.0f", [[NSDate date] timeIntervalSince1970]] ;
	[parameters setObject: timeStamp forKey: @"oauth_timestamp"] ;
	
	// OAuth nonce
	srandomdev() ;
	unsigned long nonce1 = (unsigned long) random() ;
	unsigned long nonce2 = (unsigned long) random() ;
	NSString *nonce = [NSString stringWithFormat: @"%08lx%08lx", nonce1, nonce2] ;
	[parameters setObject: nonce forKey: @"oauth_nonce"] ;
	
	// OAuth version
	[parameters setObject: @"1.0" forKey: @"oauth_version"] ;
	
	// Percent-encode and concatenate the parameter lists
	for (NSString *name in [parameters allKeys])
	{
		NSString *value = [parameters objectForKey: name] ;
		[encodedParameters setObject: [value percentEncode] forKey: [name percentEncode]] ;
	}
	
	// Sort the encoded parameters
	NSMutableArray *sortedEncodedNames = [[encodedParameters allKeys] mutableCopy] ;
	[sortedEncodedNames sortUsingSelector: @selector(compare:)] ;
	
	// Construct the signature base string first getting the Base URL
	NSString *baseURL ;
	if (queryParametersLocation != NSNotFound)
		baseURL = [URL substringToIndex: queryParametersLocation] ;
	else
		baseURL = URL ;
	
	NSString *encodedBaseURL = [URL percentEncode] ;
	
	// Next make the parameters string
	NSMutableString *parametersString = [NSMutableString string] ;
	NSUInteger index = 1 ;
	for (NSString *encodedName in sortedEncodedNames)
	{
		[parametersString appendFormat: @"%@=%@", encodedName, [encodedParameters objectForKey: encodedName]] ;
		if (index < [sortedEncodedNames count])
			[parametersString appendString: @"&"] ;
		index++ ;
	}
	
	// percent encode the string
	NSString *encodedParametersString = [parametersString percentEncode] ;
	
	// Put together all the parts of the base string
	NSString *baseString = [NSString stringWithFormat: @"%@&%@&%@", method, encodedBaseURL, encodedParametersString] ;
	
	// Calculate the signature
	NSMutableString *key = [NSMutableString string] ;
	if (consumerKeySecret)
		[key appendString: [consumerKeySecret percentEncode]] ;
	[key appendString: @"&"] ;
	if (tokenSecret)
		[key appendString: [tokenSecret percentEncode]] ;
	
	unsigned char HMAC_string[CC_SHA1_DIGEST_LENGTH] ;
	CCHmac(kCCHmacAlgSHA1, [key UTF8String], [key lengthOfBytesUsingEncoding: NSUTF8StringEncoding], [baseString UTF8String], [baseString lengthOfBytesUsingEncoding: NSUTF8StringEncoding], HMAC_string) ;
	NSData *HMACData = [[NSData alloc] initWithBytes: HMAC_string length: sizeof(HMAC_string)] ;
	NSString *oauthSignature = [HMACData base64EncodeWithLength: CC_SHA1_DIGEST_LENGTH] ;
	
	// In function of whether the signature is a authorization header or plain normalized parameters
	NSMutableString *authorization = [NSMutableString string] ;
	if (headerStyle == YES)
		[authorization appendString: @"OAuth "] ;
	
	// add all paramters
	for (NSString *encodedName in sortedEncodedNames)
	{
		if (headerStyle)
			[authorization appendFormat: @"%@=\"%@\"", encodedName, [encodedParameters objectForKey: encodedName]] ;
		else
			[authorization appendFormat: @"%@=%@", encodedName, [encodedParameters objectForKey: encodedName]] ;
		
		if (headerStyle)
			[authorization appendString: @", "] ;
		else
			[authorization appendString: @"&"] ;
	}
	
	// finally append the signature
	if (headerStyle)
		[authorization appendFormat: @"%@=\"%@\"", [@"oauth_signature" percentEncode], [oauthSignature percentEncode]] ;
	else
		[authorization appendFormat: @"%@=%@", [@"oauth_signature" percentEncode], [oauthSignature percentEncode]] ;
	
	return authorization ;
}

@end
