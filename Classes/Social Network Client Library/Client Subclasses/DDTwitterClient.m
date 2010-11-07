//
//  DDTwitterClient.m
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 7/29/10.
//  Copyright 2010 Damien DeVille. All rights reserved.
//

#import "DDTwitterClient.h"
#import "OAuthSign.h"
#import "JSON.h"


@interface DDTwitterClient (Private)

- (void)asynchronousRequestInitialTwitterToken ;
- (void)validateOAuthToken:(NSString *)tempOAuthToken withIdentifier:(NSString *)tempOAuthIdentifier ;

- (void)requestToTwitterStarted:(ASIHTTPRequest *)request ;
- (void)requestToTwitterFinished:(ASIHTTPRequest *)request ;
- (void)requestToTwitterFailed:(ASIHTTPRequest *)request ;

- (void)postToTwitterStarted:(ASIFormDataRequest *)post ;
- (void)postToTwitterFinished:(ASIFormDataRequest *)post ;
- (void)postToTwitterFailed:(ASIFormDataRequest *)post ;

- (void)shortenURL:(NSString *)URL withMessage:(NSString *)message ;

- (CLLocation *)currentLocation ;
- (void)tellDelegateAuthenticationFailedWithError:(NSError *)error ;

@end





@implementation DDTwitterClient


- (id)initWithDelegate:(id <DDTwitterClientDelegate>)theDelegate
{
	if (self = [super initWithDelegate: theDelegate])
	{
		[self setDelegate: theDelegate] ;
	}
	
	return self ;
}



- (DDSocialNetworkClientType)clientType
{
	return kDDSocialNetworkClientTypeTwitter ;
}



+ (NSString *)clientServiceKey
{
	return TWITTER_SERVICE_KEY ;
}



+ (NSString *)clientDomain
{
	return TWITTER_DOMAIN ;
}


- (NSString *)name
{
	return @"Twitter" ;
}











#pragma mark -
#pragma mark Authentication related methods

- (NSString *)authenticationURLString
{
	if (initialToken)
	{
		NSString *URLFormat = @"https://api.twitter.com/oauth/authorize?oauth_token=%@" ;
		return [NSString stringWithFormat: URLFormat, initialToken] ;
	}
	return nil ;
}



- (void)startLoginProcess
{
	[self asynchronousRequestInitialTwitterToken] ;
}



- (void)asynchronousRequestInitialTwitterToken
{
	NSString *URL = @"https://api.twitter.com/oauth/request_token" ;
	
	// Create the authorization header
	NSString *oauth_header = [OAuthSign getOAuthSignatureForMethod: @"GET"
															   URL: URL 
														  callback: @"about-blank"
													   consumerKey: TWITTER_CONSUMER_KEY
												 consumerKeySecret: TWITTER_CONSUMER_SECRET
															 token: nil
													   tokenSecret: nil
														  verifier: nil
													postParameters: nil
													   headerStyle: YES] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URL]] ;
	[request setRequestMethod: @"GET"] ;
	[request addRequestHeader: @"Authorization" value: oauth_header] ;
	[request setDidStartSelector: @selector(requestToTwitterStarted:)] ;
	[request setDidFinishSelector: @selector(requestToTwitterFinished:)] ;
	[request setDidFailSelector: @selector(requestToTwitterFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: @"initialTokenRequest" forKey: @"whichRequest"]] ;
	[request startAsynchronous] ;
}



- (NSDictionary *)pleaseParseThisURLResponseForMe:(NSString *)response
{
	// 41 is the length of the original substring
	if ([response length] > 41)
	{
		if ([[response substringToIndex: 41] isEqualToString: @"https://api.twitter.com/oauth/about-blank"])
		{
			// we have got what we are looking for, start parsing the shit
			NSMutableDictionary *responseDictionary = [[NSMutableDictionary alloc] initWithCapacity: 2]  ;
			
			NSRange oauthTokenRange = [response rangeOfString: @"oauth_token="] ;
			if (oauthTokenRange.length > 0)
			{
				NSString *oauthToken ;
				int fromIndex = oauthTokenRange.location + oauthTokenRange.length ;
				oauthToken = [response substringFromIndex: fromIndex] ;
				oauthToken = [oauthToken stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ;
				NSRange periodRange = [oauthToken rangeOfString: @"&"] ;
				oauthToken = [oauthToken substringToIndex: periodRange.location] ;
				
				// we print the token and build a dictionary that we return
				[responseDictionary setObject: oauthToken forKey: @"TempOAuthToken"] ;
			}
			NSRange oauthVerifierRange = [response rangeOfString: @"oauth_verifier="] ;
			if (oauthVerifierRange.length > 0)
			{
				NSString *oauthIdentifier ;
				int fromIndex = oauthVerifierRange.location + oauthVerifierRange.length ;
				oauthIdentifier = [response substringFromIndex: fromIndex] ;
				oauthIdentifier = [oauthIdentifier stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ;
				
				// we print the token and build a dictionary that we return
				[responseDictionary setObject: oauthIdentifier forKey: @"TempOAuthIdentifier"] ;
			}
			return responseDictionary ;
		}
	}
	
	return nil ;
}



- (void)validateOAuthToken:(NSString *)tempOAuthToken withIdentifier:(NSString *)tempOAuthIdentifier
{
	NSString *URL = @"https://api.twitter.com/oauth/access_token" ;
	
	NSString *oauth_header = [OAuthSign getOAuthSignatureForMethod: @"GET"
															   URL: URL 
														  callback: nil
													   consumerKey: TWITTER_CONSUMER_KEY
												 consumerKeySecret: TWITTER_CONSUMER_SECRET
															 token: tempOAuthToken
													   tokenSecret: nil
														  verifier: tempOAuthIdentifier
													postParameters: nil
													   headerStyle: YES] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URL]] ;
	[request setRequestMethod: @"GET"] ;
	[request addRequestHeader: @"Authorization" value: oauth_header] ;
	[request setDidStartSelector: @selector(requestToTwitterStarted:)] ;
	[request setDidFinishSelector: @selector(requestToTwitterFinished:)] ;
	[request setDidFailSelector: @selector(requestToTwitterFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: @"validationTokenRequest" forKey: @"whichRequest"]] ;
	[request startAsynchronous] ;
}















#pragma mark -
#pragma mark Post data to Twitter methods

/*
	NOTE: this method does all the sending to Twitter.
	all other twitter related mehods (URL, image) end up
	calling this method to do the final posting.
 */
- (void)postMessageToTwitter:(NSString *)message
{
	// if there is no message, no point going further, this is an error
	if (message == nil || [message length] == 0)
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to post a message"] ;
		if (delegate && [delegate respondsToSelector: @selector(twitterPostFailedWithError:)])
			[delegate performSelectorOnMainThread: @selector(twitterPostFailedWithError:) withObject: error waitUntilDone: NO] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	// a tweet is maximum 140 characters, so we cut it if bigger
	if ([message length] > 140)
		message = [[message substringToIndex: 140-3] stringByAppendingString: @"..."] ;
	
	// we check if the delegate accepts to geolocalize its tweet
	BOOL geolocalize = NO ;
	if (![delegate respondsToSelector: @selector(shouldGeolocalizeTweet:)])
		geolocalize = NO ;
	else if ([delegate shouldGeolocalizeTweet: message])
		geolocalize = YES ;
	
	NSMutableDictionary *postBody = [NSMutableDictionary dictionaryWithObject: message forKey: @"status"] ;
	
	// we need this one if we want to add URL or other meta-shit
	[postBody setObject: @"true" forKey: @"include_entities"] ;
	
	if (geolocalize)
	{
		CLLocation *currentLocation = [self currentLocation] ;
		if (currentLocation)
		{
			[postBody setObject: [NSString stringWithFormat: @"%f", currentLocation.coordinate.latitude] forKey: @"lat"] ;
			[postBody setObject: [NSString stringWithFormat: @"%f", currentLocation.coordinate.longitude] forKey: @"long"] ;
			[postBody setObject: @"true" forKey: @"display_coordinates"] ;
		}
	}
	
	NSString *postURL = @"https://api.twitter.com/1/statuses/update.json" ;
	
	NSString *oauth_header = [OAuthSign getOAuthSignatureForMethod: @"POST"
															   URL: postURL
														  callback: nil
													   consumerKey: TWITTER_CONSUMER_KEY
												 consumerKeySecret: TWITTER_CONSUMER_SECRET
															 token: token.key
													   tokenSecret: token.secret
														  verifier: nil
													postParameters: postBody
													   headerStyle: YES] ;
	
	ASIFormDataRequest *post = [ASIFormDataRequest requestWithURL: [NSURL URLWithString: postURL]] ;
	for (NSString *key in postBody)
		[post setPostValue: [postBody objectForKey: key] forKey: key] ;
	[post addRequestHeader: @"Authorization" value: oauth_header] ;
    [post setDidStartSelector: @selector(postToTwitterStarted:)] ;
	[post setDidFinishSelector: @selector(postToTwitterFinished:)] ;
	[post setDidFailSelector: @selector(postToTwitterFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: @"postTweet" forKey: @"whichPost"]] ;
	[post startAsynchronous] ;
}



- (void)postMessageToTwitter:(NSString *)message withURL:(NSString *)URL
{
	// if no URL, we send a plain message to Twitter
	if (!URL || ![URL length])
	{
		[self postMessageToTwitter: message] ;
		return ;
	}
	
	// we first request a shorten URL
	[self shortenURL: URL withMessage: message] ;
	
	/*
		NOTE: once the shorten URL is returned, we will
		post the tweet.
	 */
}



- (void)shortenURL:(NSString *)URL withMessage:(NSString *)message
{
	NSString *percentEncodedURL = [URL stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ;
	NSString *requestURL = [NSString stringWithFormat: @"http://api.bit.ly/v3/shorten?login=%@&apiKey=%@&longUrl=%@&format=json", BIT_LY_LOGIN, BIT_LY_API_KEY, percentEncodedURL] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: requestURL]] ;
	[request setRequestMethod: @"GET"] ;
	[request setDidStartSelector: @selector(requestToTwitterStarted:)] ;
	[request setDidFinishSelector: @selector(requestToTwitterFinished:)] ;
	[request setDidFailSelector: @selector(requestToTwitterFailed:)] ;
	[request setDelegate: self] ;
	// we keep a copy of the message in the request user info dictionary
	[request setUserInfo: [NSDictionary dictionaryWithObjectsAndKeys: @"shortenURLRequest", @"whichRequest", message, @"twitterMessage", nil]] ;
	[request startAsynchronous] ;
}



- (void)postImageToTwitter:(UIImage *)image withMessage:(NSString *)message
{
	// if no image, this is a simple tweet
	if (image == nil)
	{
		[self postMessageToTwitter: message] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	/*
		NOTE: a Twitpic URL is 25 characters.
		taking into account the space between the tweet and the image
		the maximum length of the tweet message has to be 140-25-1
	 */
	if ([message length] > (140-25-1-4))
		message = [[message substringToIndex: (140-25-1-4)] stringByAppendingString: @"..."] ;
	
	NSURL *URL = [NSURL URLWithString: [NSString stringWithFormat: @"http://api.twitpic.com/1/upload.json"]] ;
	
	ASIFormDataRequest *post = [ASIFormDataRequest requestWithURL: URL] ;
	[post setRequestMethod: @"POST"] ;
	[post addPostValue: TWITPIC_API_KEY forKey: @"key"] ;
	[post addPostValue: TWITTER_CONSUMER_KEY forKey: @"consumer_token"] ;
	[post addPostValue: TWITTER_CONSUMER_SECRET forKey: @"consumer_secret"] ;
	[post addPostValue: token.key forKey: @"oauth_token"] ;
	[post addPostValue: token.secret forKey: @"oauth_secret"] ;
	if (message)
		[post addPostValue: message forKey: @"message"] ;
	[post addData: UIImageJPEGRepresentation(image, 0.8) forKey: @"media"] ;
	[post setDidStartSelector: @selector(postToTwitterStarted:)] ;
	[post setDidFinishSelector: @selector(postToTwitterFinished:)] ;
	[post setDidFailSelector: @selector(postToTwitterFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: @"postTweetAndImage" forKey: @"whichPost"]] ;
	[post startAsynchronous] ;
}










#pragma mark -
#pragma mark Various private methods

- (CLLocation *)currentLocation
{
	/*
		NOTE: we do not want to require a location only for a tweet.
		we will geolocalize the tweet only if a location is already available
		(previously loaded by the app)
	 */
	CLLocationManager *locManager = [[[CLLocationManager alloc] init] autorelease] ;
	CLLocation *currentLocation = [locManager location] ;
	
	if (!currentLocation)
		return nil ;
	
	// we check the timestamp of the current location
	// if the last location was retrieved more than 15min ago, we return nil
	if ([[NSDate date] timeIntervalSinceDate: currentLocation.timestamp] > 60*15)
		return nil ;
	
	return currentLocation ;
}



/*
	NOTE: we need this method because we have to perform a selector
	with more than one object (argument) on the main thread...
 */

- (void)tellDelegateAuthenticationFailedWithError:(NSError *)error
{
	if (![NSThread isMainThread])
	{
		[self performSelectorOnMainThread: @selector(tellDelegateAuthenticationFailedWithError:) withObject: error waitUntilDone: YES] ;
		return ;
	}
	
	// this should have already been checked, but better being too prudent...
	if ([delegate respondsToSelector: @selector(socialMediaClient:authenticationDidFailWithError:)])
		[delegate socialMediaClient: self authenticationDidFailWithError: error] ;
}












#pragma mark -
#pragma mark Connection and parsing methods

- (void)requestToTwitterStarted:(ASIHTTPRequest *)request
{
	NSLog(@"started") ;
}



- (void)requestToTwitterFinished:(ASIHTTPRequest *)request
{
	NSLog(@"finished") ;
	
	NSString *requestType = [request.userInfo objectForKey: @"whichRequest"] ;
	
	if ([requestType isEqualToString: @"initialTokenRequest"])
	{
		if ([request error])
		{
			// we send a shout to the delegate that the authentication failed
			NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The authentication failed"] ;
			if (delegate && [delegate respondsToSelector: @selector(socialMediaClient:authenticationDidFailWithError:)])
				[self tellDelegateAuthenticationFailedWithError: error] ;
		}
		else
		{
			NSArray *responseBodyComponents = [[request responseString] componentsSeparatedByString: @"&"] ;
			for (NSString *component in responseBodyComponents)
			{
				NSArray *subComponents = [component componentsSeparatedByString: @"="] ;
				if ([[subComponents objectAtIndex: 0] isEqualToString: @"oauth_token"])
				{
					// we have our initial token, we can now show the login dialog
					initialToken = [subComponents objectAtIndex: 1] ;
					[self showLoginDialog] ;
					return ;
				}
			}
			// if we reach this point, this is an authentication error...
			// we send a shout to the delegate that the authentication failed
			NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The authentication failed"] ;
			if (delegate && [delegate respondsToSelector: @selector(socialMediaClient:authenticationDidFailWithError:)])
				[self tellDelegateAuthenticationFailedWithError: error] ;
		}
	}
	else if ([requestType isEqualToString: @"validationTokenRequest"])
	{
		if ([request error])
		{
			// we send a shout to the delegate that the authentication failed
			NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The authentication failed"] ;
			if (delegate && [delegate respondsToSelector: @selector(socialMediaClient:authenticationDidFailWithError:)])
				[self tellDelegateAuthenticationFailedWithError: error] ;
		}
		else
		{
			NSArray *responseBodyComponents = [[request responseString] componentsSeparatedByString: @"&"] ;
			NSString *theToken = nil ;
			NSString *theTokenSecret = nil ;
			for (NSString *component in responseBodyComponents)
			{
				NSArray *subComponents = [component componentsSeparatedByString: @"="] ;
				if ([[subComponents objectAtIndex: 0] isEqualToString: @"oauth_token"])
					theToken = [subComponents objectAtIndex: 1] ;
				if ([[subComponents objectAtIndex: 0] isEqualToString: @"oauth_token_secret"])
					theTokenSecret = [subComponents objectAtIndex: 1] ;
			}
			
			// we create a token, and store it
			OAuthToken *newToken = [[[OAuthToken alloc] initWithService: [[self class] clientServiceKey] andKey: theToken andSecret: theTokenSecret] autorelease] ;
			[self setToken: newToken] ;
			[self.token storeToUserDefaults] ;
			// we give a shout to the delegate
			if (delegate && [delegate respondsToSelector: @selector(socialMediaClientAuthenticationDidSucceed:)])
				[delegate performSelectorOnMainThread: @selector(socialMediaClientAuthenticationDidSucceed:) withObject: self waitUntilDone: NO] ;
			// and close the login dialog
			[loginDialog dismissModalViewControllerAnimated: YES] ;
		}
	}
	else if ([requestType isEqualToString: @"shortenURLRequest"])
	{
		NSString *responseString = [request responseString] ;
		NSMutableDictionary *responseJSON = [responseString JSONValue] ;
		
		if ([[responseJSON objectForKey: @"status_code"] intValue] != 200)
		{
			// failing the shorten URL request means failing the whole tweet....
			// we then say the delagate about it....
			NSLog(@"post failed") ;
			NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The post to Twitter failed"] ;
			if (delegate && [delegate respondsToSelector: @selector(twitterPostFailedWithError:)])
				[delegate performSelectorOnMainThread: @selector(twitterPostFailedWithError:) withObject: error waitUntilDone: NO] ;
		}
		else
		{
			// we get the tweet message back from the user info dictionary
			NSString *message = [request.userInfo objectForKey: @"twitterMessage"] ;
			
			// we parse the response to get the shorten URL and finally send the post to Twitter
			NSDictionary *dataDic = [responseJSON objectForKey: @"data"] ;
			NSString *shortURL = [dataDic objectForKey: @"url"] ;

			if (([message length]+[shortURL length]+1) > 140)
				message = [[message substringToIndex: (140-[shortURL length]-1-3)] stringByAppendingString: @"..."] ;
				
			message = [NSString stringWithFormat: @"%@ %@", message, shortURL] ;
				
			// our URL is now completely shortened, we can post to twitter
			[self postMessageToTwitter: message] ;
		}
	}
}



- (void)requestToTwitterFailed:(ASIHTTPRequest *)request
{
	NSLog(@"failed") ;
	
	NSString *requestType = [request.userInfo objectForKey: @"whichRequest"] ;
	
	if ([requestType isEqualToString: @"initialTokenRequest"] || [requestType isEqualToString: @"validationTokenRequest"])
	{
		// we send a shout to the delegate that the authentication failed
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The authentication failed"] ;
		if (delegate && [delegate respondsToSelector: @selector(socialMediaClient:authenticationDidFailWithError:)])
			[self tellDelegateAuthenticationFailedWithError: error] ;
	}
	else if ([requestType isEqualToString: @"shortenURLRequest"])
	{
		// failing the shorten URL request means failing the whole tweet....
		// we then say the delagate about it....
		NSLog(@"post failed") ;
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The post to Twitter failed"] ;
		if (delegate && [delegate respondsToSelector: @selector(twitterPostFailedWithError:)])
			[delegate performSelectorOnMainThread: @selector(twitterPostFailedWithError:) withObject: error waitUntilDone: NO] ;
	}
}



- (void)postToTwitterStarted:(ASIFormDataRequest *)post
{
	NSLog(@"post started") ;
}



- (void)postToTwitterFinished:(ASIFormDataRequest *)post
{
	NSLog(@"post finished") ;
	
	NSString *postType = [post.userInfo objectForKey: @"whichPost"] ;
	
	// for both Twitter and Twitpic, we parse the same data
	NSString *responseString = [post responseString] ;
	NSMutableDictionary *responseJSON = [responseString JSONValue] ;
	
	if ([postType isEqualToString: @"postTweet"])
	{
		// if the status code is not 200, that is an error of some sort
		if (post.responseStatusCode != 200)
		{
			NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The post to Twitter failed"] ;
			if (delegate && [delegate respondsToSelector: @selector(twitterPostFailedWithError:)])
				[delegate performSelectorOnMainThread: @selector(twitterPostFailedWithError:) withObject: error waitUntilDone: NO] ;
		}
		else
		{
			if (delegate && [delegate respondsToSelector: @selector(twitterPostDidSucceedAndReturned:)])
				[delegate performSelectorOnMainThread: @selector(twitterPostDidSucceedAndReturned:) withObject: responseJSON waitUntilDone: NO] ;
		}
	}
	else if ([postType isEqualToString: @"postTweetAndImage"])
	{
		// if the status code is not 200, that is an error of some sort
		if (post.responseStatusCode != 200)
		{
			NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The post to Twitpic failed"] ;
			if (delegate && [delegate respondsToSelector: @selector(twitterPostFailedWithError:)])
				[delegate performSelectorOnMainThread: @selector(twitterPostFailedWithError:) withObject: error waitUntilDone: NO] ;
		}
		else
		{
			// we now retrieve the message and image and post as a URL
			NSString *URL = [responseJSON objectForKey: @"url"] ;
			NSString *message = [responseJSON objectForKey: @"text"] ;
			
			[self postMessageToTwitter: [NSString stringWithFormat: @"%@ %@", message, URL]] ;
		}
	}
}



- (void)postToTwitterFailed:(ASIFormDataRequest *)post
{
	NSLog(@"post failed") ;
	
	NSString *postType = [post.userInfo objectForKey: @"whichPost"] ;
	
	if ([postType isEqualToString: @"postTweet"])
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The post to Twitter failed"] ;
		if (delegate && [delegate respondsToSelector: @selector(twitterPostFailedWithError:)])
			[delegate performSelectorOnMainThread: @selector(twitterPostFailedWithError:) withObject: error waitUntilDone: NO] ;
	}
	else if ([postType isEqualToString: @"postTweetAndImage"])
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The post to Twitpic failed"] ;
		if (delegate && [delegate respondsToSelector: @selector(twitterPostFailedWithError:)])
			[delegate performSelectorOnMainThread: @selector(twitterPostFailedWithError:) withObject: error waitUntilDone: NO] ;
	}
}


@end
