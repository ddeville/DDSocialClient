//
//  OAuthSign.h
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 8/5/10.
//  Copyright 2010 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>





/*
	OAuthSign is a wrapper around the excellent C-function
	oauth_sign written by Jef Poskanzer.
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
		- body				-->	the POST body
 */

@interface OAuthSign : NSObject
{

}

+ (NSString *)getOAuthSignatureForMethod:(NSString *)method 
									 URL:(NSString *)URL 
								callback:(NSString *)callback 
							 consumerKey:(NSString *)consumerKey 
					   consumerKeySecret:(NSString *)consumerKeySecret 
								   token:(NSString *)token 
							 tokenSecret:(NSString *)tokenSecret
								verifier:(NSString *)verifier 
									body:(NSDictionary *)body ;


@end
