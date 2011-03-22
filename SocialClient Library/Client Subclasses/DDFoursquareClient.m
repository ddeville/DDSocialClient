//
//  DDFoursquareClient.m
//  SocialClient
//
//  Created by Damien DeVille on 3/22/11.
//  Copyright 2011 Snappy Code. All rights reserved.
//

#import "DDFoursquareClient.h"
#import "JSON.h"

#define foursquarePostType		@"FoursquarePostType"
#define foursquareRequestType	@"FoursquareRequestType"

@implementation DDFoursquareClient

@dynamic delegate ;

- (id)initWithDelegate:(id <DDFoursquareClientDelegate>)theDelegate
{
	if ((self = [super initWithDelegate: theDelegate]))
	{
		[self setDelegate: theDelegate] ;
	}
	
	return self ;
}

- (void)dealloc
{
	[super dealloc] ;
}

- (DDSocialClientType)clientType
{
	return kDDSocialClientFoursquare ;
}

+ (NSString *)clientServiceKey
{
	return FOURSQUARE_SERVICE_KEY ;
}

+ (NSString *)clientDomain
{
	return FOURSQUARE_DOMAIN ;
}

- (NSString *)name
{
	return @"Foursquare" ;
}



#pragma mark -
#pragma mark Authentication methods

- (NSString *)authenticationURLString
{
	NSString *authFormatString = @"https://foursquare.com/oauth2/authenticate?client_id=%@&response_type=code&redirect_uri=%@" ;
	NSString *urlString = [NSString stringWithFormat: authFormatString, FOURSQUARE_API_KEY, FOURSQUARE_CALLBACK] ;
	return urlString ;
}

- (void)login
{
	if ([FOURSQUARE_API_KEY length] == 0)
	{
		NSLog(@"You need to specify FOURSQUARE_API_KEY in DDSocialClient.h") ;
		
		NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 7 userInfo: [NSDictionary dictionaryWithObject: @"Unspecified API key." forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
			[delegate socialClient: self authenticationDidFailWithError: error] ;
		return ;
	}
	
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable)
	{
		NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 1 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because there is no Internet connection." forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
			[delegate socialClient: self authenticationDidFailWithError: error] ;
		return ;
	}
	
	[self showLoginDialog] ;
}

- (NSDictionary *)parseURL:(NSString *)URL
{
	NSRange codeRange = [URL rangeOfString: @"code="] ;
	if (codeRange.length > 0)
	{
		NSString *code = nil ;
		int fromIndex = codeRange.location + codeRange.length ;
		code = [URL substringFromIndex: fromIndex] ;
		code = [code stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ;
		
		// we build a dictionary with the token that we return
		return [NSDictionary dictionaryWithObject: code forKey: @"TempOAuthToken"] ;
	}
	return nil ;
}

- (void)validateOAuthToken:(NSString *)tempOAuthToken withIdentifier:(NSString *)tempOAuthIdentifier
{
	NSString *URL = [NSString stringWithFormat: @"https://foursquare.com/oauth2/access_token?client_id=%@&client_secret=%@&grant_type=authorization_code&redirect_uri=%@&code=%@", FOURSQUARE_API_KEY, FOURSQUARE_API_SECRET, FOURSQUARE_CALLBACK, tempOAuthToken] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URL]] ;
	[request setRequestMethod: @"GET"] ;
	[request setDidStartSelector: @selector(requestToFoursquareStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFoursquareFinished:)] ;
	[request setDidFailSelector: @selector(requestToFoursquareFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: @"validationTokenRequest" forKey: foursquareRequestType]] ;
	[request startAsynchronous] ;
}



#pragma mark -
#pragma mark ASIHTTPRequest delegate methods

- (void)requestToFoursquareStarted:(ASIHTTPRequest *)request
{
	
}

- (void)requestToFoursquareFinished:(ASIHTTPRequest *)request
{
	NSString *requestType = [request.userInfo objectForKey: foursquareRequestType] ;
	
	if ([requestType isEqualToString: @"validationTokenRequest"])
	{
		if ([request error])
		{
			// dismiss the login dialog
			[loginDialog dismissAnimated: YES] ;
			
			// we send a shout to the delegate that the authentication failed
			NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 6 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the OAuth token failed." forKey: NSLocalizedDescriptionKey]] ;
			if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
				[delegate socialClient: self authenticationDidFailWithError: error] ;
		}
		else
		{
			NSDictionary *tokenJSON = [[request responseString] JSONValue] ;
			NSString *theToken = [tokenJSON objectForKey: @"access_token"] ;
			if (theToken)
			{
				// we create a token, and store it
				OAuthToken *newToken = [[[OAuthToken alloc] initWithService: [[self class] clientServiceKey] andKey: theToken andSecret: @"NoSecretForThisClient"] autorelease] ;
				[self setToken: newToken] ;
				[self.token store] ;
				// we give a shout to the delegate
				if (delegate && [delegate respondsToSelector: @selector(socialClientAuthenticationDidSucceed:)])
					[delegate performSelectorOnMainThread: @selector(socialClientAuthenticationDidSucceed:) withObject: self waitUntilDone: NO] ;
				// and close the login dialog
				[loginDialog dismissAnimated: YES] ;
			}
			else
			{
				// dismiss the login dialog
				[loginDialog dismissAnimated: YES] ;
				
				// we send a shout to the delegate that the authentication failed
				NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 6 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the OAuth token failed." forKey: NSLocalizedDescriptionKey]] ;
				if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
					[delegate socialClient: self authenticationDidFailWithError: error] ;
			}
		}
	}
}

- (void)requestToFoursquareFailed:(ASIHTTPRequest *)request
{
	NSString *requestType = [request.userInfo objectForKey: foursquareRequestType] ;
	
	if ([requestType isEqualToString: @"validationTokenRequest"])
	{
		if ([request error])
		{
			// dismiss the login dialog
			[loginDialog dismissAnimated: YES] ;
			
			// we send a shout to the delegate that the authentication failed
			NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 6 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the OAuth token failed." forKey: NSLocalizedDescriptionKey]] ;
			if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
				[delegate socialClient: self authenticationDidFailWithError: error] ;
		}
	}
}

@end
