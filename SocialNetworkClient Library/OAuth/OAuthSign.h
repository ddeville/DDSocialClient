//
//  OAuthSign.h
//  SocialNetworkClient
//
//  Created by Damien DeVille on 8/5/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import <Foundation/Foundation.h>

/*
	OAuthSign defines methods than compute a HMAC-SHA1 signature and
	return an authorization string according to the OAuth protocol.
	Arguments are optional so you are free to pass nil if
	you don't have or require something.
	
	Arguments:
		- method			--> GET, POST or HEAD
		- URL				--> the URL we are posting to
		- callback			--> the URL where we want to be redirect after the signing
		- consumerKey		--> the consumer (client) key
		- consumerKeySecret	--> the consumer (client) key secret
		- token				-->	the OAuth token
		- tokenSecret		--> the OAuth token secret
		- verifier			-->	the verifier token
		- postParameters	--> the POST parameters
 */

@interface OAuthSign : NSObject
{

}

/*
	Returns the OAuth parameters already arranged to be used as an
	authorization header in a POST.
 */
+ (NSString *)generateOAuthAuthorizationHeaderForMethod:(NSString *)method
													URL:(NSString *)URL
											   callback:(NSString *)callback
											consumerKey:(NSString *)consumerKey
									  consumerKeySecret:(NSString *)consumerKeySecret
												  token:(NSString *)token
											tokenSecret:(NSString *)tokenSecret
											   verifier:(NSString *)verifier
										 postParameters:(NSDictionary *)postParameters ;

/*
	Returns the OAuth parameters already arranged to be appended to a URL
	as query parameters.
 */
+ (NSString *)generateOAuthQueryParametersForMethod:(NSString *)method
												URL:(NSString *)URL
										   callback:(NSString *)callback
										consumerKey:(NSString *)consumerKey
								  consumerKeySecret:(NSString *)consumerKeySecret
											  token:(NSString *)token
										tokenSecret:(NSString *)tokenSecret
										   verifier:(NSString *)verifier
									 postParameters:(NSDictionary *)postParameters ;

/*
	Returns the OAuth parameters arranged in a dictionary.
 */
+ (NSDictionary *)getOAuthParametersForMethod:(NSString *)method
										  URL:(NSString *)URL
									 callback:(NSString *)callback
								  consumerKey:(NSString *)consumerKey
							consumerKeySecret:(NSString *)consumerKeySecret
										token:(NSString *)token
								  tokenSecret:(NSString *)tokenSecret
									 verifier:(NSString *)verifier
							   postParameters:(NSDictionary *)postParameters ;

@end
