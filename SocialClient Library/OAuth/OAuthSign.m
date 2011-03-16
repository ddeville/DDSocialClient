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

+ (NSString *)generateOAuthAuthorizationHeaderForMethod:(NSString *)method URL:(NSString *)URL callback:(NSString *)callback consumerKey:(NSString *)consumerKey consumerKeySecret:(NSString *)consumerKeySecret token:(NSString *)token tokenSecret:(NSString *)tokenSecret verifier:(NSString *)verifier postParameters:(NSDictionary *)postParameters
{
	// first generate the OAuth parameters
	NSDictionary *oauthParameters = [self getOAuthParametersForMethod: method
																  URL: URL
															 callback: callback
														  consumerKey: consumerKey
													consumerKeySecret: consumerKeySecret
																token: token
														  tokenSecret: tokenSecret
															 verifier: verifier
													   postParameters: postParameters] ;
	
	NSMutableString *authorization = [NSMutableString string] ;
	
	// add the protocol name
	[authorization appendString: @"OAuth "] ;
	
	// append all OAuth paramters
	NSUInteger count = 1 ;
	for (NSString *name in oauthParameters)
	{
		[authorization appendFormat: @"%@=\"%@\"", name, [oauthParameters objectForKey: name]] ;
		if (count < [oauthParameters count])
			[authorization appendString: @", "] ;
		count++ ;
	}
	
	return authorization ;
}

+ (NSString *)generateOAuthQueryParametersForMethod:(NSString *)method URL:(NSString *)URL callback:(NSString *)callback consumerKey:(NSString *)consumerKey consumerKeySecret:(NSString *)consumerKeySecret token:(NSString *)token tokenSecret:(NSString *)tokenSecret verifier:(NSString *)verifier postParameters:(NSDictionary *)postParameters
{
	// first generate the OAuth parameters
	NSDictionary *oauthParameters = [self getOAuthParametersForMethod: method
																  URL: URL
															 callback: callback
														  consumerKey: consumerKey
													consumerKeySecret: consumerKeySecret
																token: token
														  tokenSecret: tokenSecret
															 verifier: verifier
													   postParameters: postParameters] ;
	
	NSMutableString *authorization = [NSMutableString string] ;
	
	// append all OAuth paramters
	NSUInteger count = 1 ;
	for (NSString *name in oauthParameters)
	{
		[authorization appendFormat: @"%@=%@", name, [oauthParameters objectForKey: name]] ;
		if (count < [oauthParameters count])
			[authorization appendString: @"&"] ;
		count++ ;
	}
	
	return authorization ;
}

+ (NSDictionary *)getOAuthParametersForMethod:(NSString *)method URL:(NSString *)URL callback:(NSString *)callback consumerKey:(NSString *)consumerKey consumerKeySecret:(NSString *)consumerKeySecret token:(NSString *)token tokenSecret:(NSString *)tokenSecret verifier:(NSString *)verifier postParameters:(NSDictionary *)postParameters
{
	NSMutableDictionary *protocolParameters = [NSMutableDictionary dictionary] ;
	NSMutableDictionary *allParameters = [NSMutableDictionary dictionary] ;
	NSString *parameterName ;
	NSString *parameterValue ;
	
	// Assign values to the OAuth protocol parameters (some are optional)
	
	// OAuth version
	parameterName = [@"oauth_version" percentEncode] ;
	parameterValue = [@"1.0" percentEncode] ;
	[protocolParameters setObject: parameterValue forKey: parameterName] ;
	
	// OAuth signature method
	parameterName = [@"oauth_signature_method" percentEncode] ;
	parameterValue = [@"HMAC-SHA1" percentEncode] ;
	[protocolParameters setObject: parameterValue forKey: parameterName] ;
	
	// OAuth time stamp
	NSString *timeStamp = [NSString stringWithFormat: @"%.0f", [[NSDate date] timeIntervalSince1970]] ;
	parameterName = [@"oauth_timestamp" percentEncode] ;
	parameterValue = [timeStamp percentEncode] ;
	[protocolParameters setObject: parameterValue forKey: parameterName] ;
	
	// OAuth nonce
	srandomdev() ;
	unsigned long nonce1 = (unsigned long) random() ;
	unsigned long nonce2 = (unsigned long) random() ;
	NSString *nonce = [NSString stringWithFormat: @"%08lx%08lx", nonce1, nonce2] ;
	parameterName = [@"oauth_nonce" percentEncode] ;
	parameterValue = [nonce percentEncode] ;
	[protocolParameters setObject: parameterValue forKey: parameterName] ;
	
	// OAuth consumer key
	if (consumerKey)
	{
		parameterName = [@"oauth_consumer_key" percentEncode] ;
		parameterValue = [consumerKey percentEncode] ;
		[protocolParameters setObject: parameterValue forKey: parameterName] ;
	}
	
	// OAuth token
	if (token)
	{
		parameterName = [@"oauth_token" percentEncode] ;
		parameterValue = [token percentEncode] ;
		[protocolParameters setObject: parameterValue forKey: parameterName] ;
	}
	
	// OAuth callback
	if (callback)
	{
		parameterName = [@"oauth_callback" percentEncode] ;
		parameterValue = [callback percentEncode] ;
		[protocolParameters setObject: parameterValue forKey: parameterName] ;
	}
	
	// OAuth verifier
	if (verifier)
	{
		parameterName = [@"oauth_verifier" percentEncode] ;
		parameterValue = [verifier percentEncode] ;
		[protocolParameters setObject: parameterValue forKey: parameterName] ;
	}
	
	// add the protocol parameters to the global list of parameters
	[allParameters addEntriesFromDictionary: protocolParameters] ;
	
	// Check whether the URL contains URL query parameters
	NSUInteger queryParametersLocation = [URL rangeOfString: @"?"].location ;
	
	// if the URL has query parameters
	if (queryParametersLocation != NSNotFound && [URL length] > queryParametersLocation)
	{
		// get the query parameters part of the URL
		NSString *parametersString = [URL substringFromIndex: queryParametersLocation + 1] ;
		
		// get the name=value parameter components
		NSArray *queryParameters = [parametersString componentsSeparatedByString: @"&"] ;
		
		// get the query parameters as a couple of name and value
		for (NSString *singleParameter in queryParameters)
		{
			NSArray *parameter = [singleParameter componentsSeparatedByString: @"="] ;
			if ([parameter count] > 1)
			{
				parameterName = [[[parameter objectAtIndex: 0] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] percentEncode] ;
				parameterValue = [[[parameter objectAtIndex: 1] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] percentEncode] ;
				[allParameters setObject: parameterValue forKey: parameterName] ;
			}
		}
	}
	
	// get the eventual POST parameters
	for (NSString *name in postParameters)
	{
		parameterName = [name stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ;
		parameterValue = [[[postParameters objectForKey: name] stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] percentEncode] ;
		
		[allParameters setObject: parameterValue forKey: parameterName] ;
	}
	
	// Sort the parameters
	NSMutableArray *sortedNames = [[allParameters allKeys] mutableCopy] ;
	[sortedNames sortUsingSelector: @selector(compare:)] ;
	
	// Construct the signature base string first getting the Base URL
	NSString *baseURL = URL ;
	if (queryParametersLocation != NSNotFound)
		baseURL = [URL substringToIndex: queryParametersLocation] ;
	
	// percent encode the base URL
	NSString *encodedBaseURL = [baseURL percentEncode] ;
	
	// Next make the parameters string
	NSMutableString *parametersString = [NSMutableString string] ;
	NSUInteger count = 1 ;
	for (NSString *name in sortedNames)
	{
		[parametersString appendFormat: @"%@=%@", name, [allParameters objectForKey: name]] ;
		if (count < [sortedNames count])
			[parametersString appendString: @"&"] ;
		count++ ;
	}
	
	[sortedNames release] ;
	
	// percent encode the parameters string
	NSString *encodedParametersString = [parametersString percentEncode] ;
	
	// Put together all the parts of the base string
	NSString *baseString = [NSString stringWithFormat: @"%@&%@&%@", method, encodedBaseURL, encodedParametersString] ;
	
	// Calculate the signature by first creating the key (consumer key secret + token secret)
	NSMutableString *key = [NSMutableString string] ;
	if (consumerKeySecret)
		[key appendString: [consumerKeySecret percentEncode]] ;
	[key appendString: @"&"] ;
	if (tokenSecret)
		[key appendString: [tokenSecret percentEncode]] ;
	
	// compute the actual signature
	unsigned char HMACString[CC_SHA1_DIGEST_LENGTH] ;
	CCHmac(kCCHmacAlgSHA1, [key UTF8String], [key lengthOfBytesUsingEncoding: NSUTF8StringEncoding], [baseString UTF8String], [baseString lengthOfBytesUsingEncoding: NSUTF8StringEncoding], HMACString) ;
	NSData *HMACData = [[NSData alloc] initWithBytes: HMACString length: sizeof(HMACString)] ;
	NSString *oauthSignature = [HMACData base64EncodeWithLength: CC_SHA1_DIGEST_LENGTH] ;
	[HMACData release] ;
	
	// add the signature to the parameters
	[protocolParameters setObject: [oauthSignature percentEncode] forKey: [@"oauth_signature" percentEncode]] ;
	
	return protocolParameters ;
}

@end
