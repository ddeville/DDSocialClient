//
//  DDLinkedInClient.m
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 11/11/10.
//  Copyright 2010 Acrossair. All rights reserved.
//

#import "DDLinkedInClient.h"
#import "OAuthSign.h"
#import "JSON.h"


#define linkedInPostType		@"LinkedInPostType"
#define linkedInRequestType		@"LinkedInRequestType"


@interface DDLinkedInClient (Private)

- (void)asynchronousRequestInitialLinkedInToken ;
- (void)validateOAuthToken:(NSString *)tempOAuthToken withIdentifier:(NSString *)tempOAuthIdentifier ;

- (void)requestToLinkedInStarted:(ASIHTTPRequest *)request ;
- (void)requestToLinkedInFinished:(ASIHTTPRequest *)request ;
- (void)requestToLinkedInFailed:(ASIHTTPRequest *)request ;

- (void)postToLinkedInStarted:(ASIFormDataRequest *)post ;
- (void)postToLinkedInFinished:(ASIFormDataRequest *)post ;
- (void)postToLinkedInFailed:(ASIFormDataRequest *)post ;

- (void)tellDelegateAuthenticationFailedWithError:(NSError *)error ;

@end



@implementation DDLinkedInClient


- (id)initWithDelegate:(id <DDLinkedInClientDelegate>)theDelegate
{
	if (self = [super initWithDelegate: theDelegate])
	{
		[self setDelegate: theDelegate] ;
	}
	
	return self ;
}

- (DDSocialNetworkClientType)clientType
{
	return kDDSocialNetworkClientTypeLinkedIn ;
}



+ (NSString *)clientServiceKey
{
	return LINKEDIN_SERVICE_KEY ;
}



+ (NSString *)clientDomain
{
	return LINKEDIN_DOMAIN ;
}


- (NSString *)name
{
	return @"LinkedIn" ;
}









#pragma mark -
#pragma mark Authentication related methods

- (NSString *)authenticationURLString
{
	if (initialToken)
	{
		NSString *URLFormat = @"https://www.linkedin.com/uas/oauth/authorize?oauth_token=%@" ;
		return [NSString stringWithFormat: URLFormat, initialToken] ;
	}
	return nil ;
}


- (void)startLoginProcess
{
	[self asynchronousRequestInitialLinkedInToken] ;
}


- (void)asynchronousRequestInitialLinkedInToken
{
	NSString *URL = @"https://api.linkedin.com/uas/oauth/requestToken" ;
	
	// Create the authorization header
	NSString *oauth_header = [OAuthSign getOAuthSignatureForMethod: @"POST"
															   URL: URL
														  callback: @"about-blank"
													   consumerKey: LINKEDIN_API_KEY
												 consumerKeySecret: LINKEDIN_API_SECRET
															 token: nil
													   tokenSecret: nil
														  verifier: nil
													postParameters: nil
													   headerStyle: YES] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URL]] ;
	[request setRequestMethod: @"POST"] ;
	[request addRequestHeader: @"Authorization" value: oauth_header] ;
	[request setDidStartSelector: @selector(requestToLinkedInStarted:)] ;
	[request setDidFinishSelector: @selector(requestToLinkedInFinished:)] ;
	[request setDidFailSelector: @selector(requestToLinkedInFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: @"initialTokenRequest" forKey: linkedInRequestType]] ;
	[request startAsynchronous] ;
}


- (NSDictionary *)pleaseParseThisURLResponseForMe:(NSString *)response
{
	// 56 is the length of the original substring
	if ([response length] > 56)
	{
		if ([[response substringToIndex: 56] isEqualToString: @"https://www.linkedin.com/uas/oauth/authorize/about-blank"])
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
	NSString *URL = @"https://api.linkedin.com/uas/oauth/accessToken" ;
	
	NSString *oauth_header = [OAuthSign getOAuthSignatureForMethod: @"POST"
															   URL: URL 
														  callback: nil
													   consumerKey: LINKEDIN_API_KEY
												 consumerKeySecret: LINKEDIN_API_SECRET
															 token: tempOAuthToken
													   tokenSecret: initialTokenSecret
														  verifier: tempOAuthIdentifier
													postParameters: nil
													   headerStyle: YES] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URL]] ;
	[request setRequestMethod: @"POST"] ;
	[request addRequestHeader: @"Authorization" value: oauth_header] ;
	[request setDidStartSelector: @selector(requestToLinkedInStarted:)] ;
	[request setDidFinishSelector: @selector(requestToLinkedInFinished:)] ;
	[request setDidFailSelector: @selector(requestToLinkedInFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: @"validationTokenRequest" forKey: linkedInRequestType]] ;
	[request startAsynchronous] ;
	
	// we can also release these two...
	[initialToken release], initialToken = nil ;
	[initialTokenSecret release], initialTokenSecret = nil ;
}


+ (void)logout
{
	// for LinkedIn, we can also invalidate the OAuth token
	OAuthToken *tokenLI = [OAuthToken tokenForService: [[self class] clientServiceKey]] ;
	if (tokenLI)
	{
		NSString *URL = @"https://api.linkedin.com/uas/oauth/invalidateToken" ;
		NSString *oauth_header = [OAuthSign getOAuthSignatureForMethod: @"GET"
																   URL: URL 
															  callback: nil
														   consumerKey: LINKEDIN_API_KEY
													 consumerKeySecret: LINKEDIN_API_SECRET
																 token: tokenLI.key
														   tokenSecret: tokenLI.secret
															  verifier: nil
														postParameters: nil
														   headerStyle: YES] ;
		
		ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URL]] ;
		[request setRequestMethod: @"GET"] ;
		[request addRequestHeader: @"Authorization" value: oauth_header] ;
		[request startAsynchronous] ;
	}
	
	// we now remove the token from the user defaults
	[OAuthToken deleteTokenFromUserDefaultsForService: [[self class] clientServiceKey]] ;
	
	// we remove the cookies for the current service
	NSString *serviceCookieDomain = [[self class] clientDomain] ;
	
	for (NSHTTPCookie* cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
	{
		NSRange textRange = [[cookie.domain lowercaseString] rangeOfString:[serviceCookieDomain lowercaseString]] ;
		// we have to make sure none of these is nil
		if (cookie.domain && serviceCookieDomain)
		{
			if(textRange.location != NSNotFound)
				[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie: cookie] ;
		}
	}
}









#pragma mark -
#pragma mark Post data to LinkedIn methods

- (void)postMessage:(NSString *)message visibilityConnectionsOnly:(BOOL)connectionsOnly
{
	// if there is no message and no title, no point going further, this is an error
	if (message == nil || [message length] == 0)
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to post a message"] ;
		if (delegate && [delegate respondsToSelector: @selector(linkedInPostFailedWithError:)])
			[delegate performSelectorOnMainThread: @selector(linkedInPostFailedWithError:) withObject: error waitUntilDone: NO] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	// the message is maximum 700 characters
	if (message && [message length] > 700)
		message = [message substringToIndex: 700] ;
	
	// create the XML content given the message and visibility
	NSString *visibility = connectionsOnly ? @"connections-only" : @"anyone" ;
	NSString *visibilityXML = [NSString stringWithFormat: @"<visibility><code>%@</code></visibility>", visibility] ;
	NSString *XML = [NSString stringWithFormat: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><share><comment>%@</comment>%@</share>", message, visibilityXML] ;
	
	NSString *postURL = @"http://api.linkedin.com/v1/people/~/shares" ;
	
	NSString *oauth_header = [OAuthSign getOAuthSignatureForMethod: @"POST"
															   URL: postURL
														  callback: nil
													   consumerKey: LINKEDIN_API_KEY
												 consumerKeySecret: LINKEDIN_API_SECRET
															 token: token.key
													   tokenSecret: token.secret
														  verifier: nil
													postParameters: nil
													   headerStyle: YES] ;
	
	ASIHTTPRequest *post = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: postURL]] ;
	[post setRequestMethod: @"POST"] ;
	[post addRequestHeader: @"Authorization" value: oauth_header] ;
	[post appendPostData: [XML dataUsingEncoding: NSUTF8StringEncoding]] ;
    [post setDidStartSelector: @selector(postToLinkedInStarted:)] ;
	[post setDidFinishSelector: @selector(postToLinkedInFinished:)] ;
	[post setDidFailSelector: @selector(postToLinkedInFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDLinkedInPostMessage] forKey: linkedInPostType]] ;
	[post startAsynchronous] ;
}


- (void)postLinkWithTitle:(NSString *)linkTitle andLink:(NSString *)URL andLinkImage:(NSString *)imageURL andLinkDescription:(NSString *)description visibilityConnectionsOnly:(BOOL)connectionsOnly
{
	// we need both title and URL
	if ((linkTitle == nil || [linkTitle length] == 0) && (URL == nil || [URL length] == 0))
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to post a title and a link"] ;
		if (delegate && [delegate respondsToSelector: @selector(linkedInPostFailedWithError:)])
			[delegate performSelectorOnMainThread: @selector(linkedInPostFailedWithError:) withObject: error waitUntilDone: NO] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	// the title is maximum 200 characters
	if (linkTitle && [linkTitle length] > 200)
		linkTitle = [linkTitle substringToIndex: 200] ;
	
	// the description is maximum 400 characters
	if (description && [description length] > 400)
		description = [description substringToIndex: 400] ;
	
	// create the XML content given the message and visibility
	NSString *visibility = connectionsOnly ? @"connections-only" : @"anyone" ;
	NSString *visibilityXML = [NSString stringWithFormat: @"<visibility><code>%@</code></visibility>", visibility] ;
	NSString *contentXML = [NSString stringWithFormat: @"<title>%@</title><submitted-url>%@</submitted-url>", linkTitle, URL] ;
	if (imageURL && [imageURL length] > 0)
		contentXML = [NSString stringWithFormat: @"%@<submitted-image-url>%@</submitted-image-url>", contentXML, imageURL] ;
	if (description && [description length] > 0)
		contentXML = [NSString stringWithFormat: @"%@<description>%@</description>", contentXML, description] ;
	NSString *XML = [NSString stringWithFormat: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><share><content>%@</content>%@</share>", contentXML, visibilityXML] ;
	
	NSString *postURL = @"http://api.linkedin.com/v1/people/~/shares" ;
	
	NSString *oauth_header = [OAuthSign getOAuthSignatureForMethod: @"POST"
															   URL: postURL
														  callback: nil
													   consumerKey: LINKEDIN_API_KEY
												 consumerKeySecret: LINKEDIN_API_SECRET
															 token: token.key
													   tokenSecret: token.secret
														  verifier: nil
													postParameters: nil
													   headerStyle: YES] ;
	
	ASIHTTPRequest *post = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: postURL]] ;
	[post setRequestMethod: @"POST"] ;
	[post addRequestHeader: @"Authorization" value: oauth_header] ;
	[post appendPostData: [XML dataUsingEncoding: NSUTF8StringEncoding]] ;
    [post setDidStartSelector: @selector(postToLinkedInStarted:)] ;
	[post setDidFinishSelector: @selector(postToLinkedInFinished:)] ;
	[post setDidFailSelector: @selector(postToLinkedInFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDLinkedInPostLink] forKey: linkedInPostType]] ;
	[post startAsynchronous] ;
}


- (void)postMessage:(NSString *)message withLinkTitle:(NSString *)linkTitle andLink:(NSString *)URL andLinkImage:(NSString *)imageURL andLinkDescription:(NSString *)description visibilityConnectionsOnly:(BOOL)connectionsOnly
{
	// if there is no message and no title, no point going further, this is an error
	if ((message == nil || [message length] == 0) && (linkTitle == nil || [linkTitle length] == 0) && (imageURL == nil || [imageURL length] == 0))
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to post a message or a title"] ;
		if (delegate && [delegate respondsToSelector: @selector(linkedInPostFailedWithError:)])
			[delegate performSelectorOnMainThread: @selector(linkedInPostFailedWithError:) withObject: error waitUntilDone: NO] ;
		return ;
	}
	
	// if no message, simply post the link
	if (message == nil || [message length] == 0)
	{
		[self postLinkWithTitle: linkTitle andLink: URL andLinkImage: imageURL andLinkDescription: description visibilityConnectionsOnly: connectionsOnly] ;
		return ;
	}
	// if no title, simply post the message
	if (linkTitle == nil || [linkTitle length] == 0)
	{
		[self postMessage: message visibilityConnectionsOnly: connectionsOnly] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	// the message is maximum 700 characters
	if (message && [message length] > 700)
		message = [message substringToIndex: 700] ;
	
	// the title is maximum 200 characters
	if (linkTitle && [linkTitle length] > 200)
		linkTitle = [linkTitle substringToIndex: 200] ;
	
	// the description is maximum 400 characters
	if (description && [description length] > 400)
		description = [description substringToIndex: 400] ;
	
	// create the XML content given the message and visibility
	NSString *visibility = connectionsOnly ? @"connections-only" : @"anyone" ;
	NSString *visibilityXML = [NSString stringWithFormat: @"<visibility><code>%@</code></visibility>", visibility] ;
	NSString *commentXML = [NSString stringWithFormat: @"<comment>%@</comment>", message] ;
	NSString *innerContent = [NSString stringWithFormat: @"<title>%@</title><submitted-url>%@</submitted-url>", linkTitle, URL] ;
	if (imageURL && [imageURL length] > 0)
		innerContent = [NSString stringWithFormat: @"%@<submitted-image-url>%@</submitted-image-url>", innerContent, imageURL] ;
	if (description && [description length] > 0)
		innerContent = [NSString stringWithFormat: @"%@<description>%@</description>", innerContent, description] ;
	NSString *contentXML = [NSString stringWithFormat: @"<content>%@</content>", innerContent] ;
	NSString *XML = [NSString stringWithFormat: @"<?xml version=\"1.0\" encoding=\"UTF-8\"?><share>%@%@%@</share>", commentXML, contentXML, visibilityXML] ;
	
	NSString *postURL = @"http://api.linkedin.com/v1/people/~/shares" ;
	
	NSString *oauth_header = [OAuthSign getOAuthSignatureForMethod: @"POST"
															   URL: postURL
														  callback: nil
													   consumerKey: LINKEDIN_API_KEY
												 consumerKeySecret: LINKEDIN_API_SECRET
															 token: token.key
													   tokenSecret: token.secret
														  verifier: nil
													postParameters: nil
													   headerStyle: YES] ;
	
	ASIHTTPRequest *post = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: postURL]] ;
	[post setRequestMethod: @"POST"] ;
	[post addRequestHeader: @"Authorization" value: oauth_header] ;
	[post appendPostData: [XML dataUsingEncoding: NSUTF8StringEncoding]] ;
    [post setDidStartSelector: @selector(postToLinkedInStarted:)] ;
	[post setDidFinishSelector: @selector(postToLinkedInFinished:)] ;
	[post setDidFailSelector: @selector(postToLinkedInFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDLinkedInPostMessageAndLink] forKey: linkedInPostType]] ;
	[post startAsynchronous] ;
}

















#pragma mark -
#pragma mark Various private methods
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
#pragma mark ASIHTTPRequest delegate methods

- (void)requestToLinkedInStarted:(ASIHTTPRequest *)request
{
	
}

- (void)requestToLinkedInFinished:(ASIHTTPRequest *)request
{
	NSString *requestType = [request.userInfo objectForKey: linkedInRequestType] ;
	
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
					initialToken = [subComponents objectAtIndex: 1] ;
					[initialToken retain] ;
				}
				if ([[subComponents objectAtIndex: 0] isEqualToString: @"oauth_token_secret"])
				{
					initialTokenSecret = [subComponents objectAtIndex: 1] ;
					[initialTokenSecret retain] ;
				}
			}
			
			if (initialToken && initialTokenSecret)
			{
				// we have our initial token, we can now show the login dialog
				[self showLoginDialog] ;
				return ;
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
}

- (void)requestToLinkedInFailed:(ASIHTTPRequest *)request
{
	NSString *requestType = [request.userInfo objectForKey: linkedInRequestType] ;
	
	if ([requestType isEqualToString: @"initialTokenRequest"] || [requestType isEqualToString: @"validationTokenRequest"])
	{
		// we send a shout to the delegate that the authentication failed
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The authentication failed"] ;
		if (delegate && [delegate respondsToSelector: @selector(socialMediaClient:authenticationDidFailWithError:)])
			[self tellDelegateAuthenticationFailedWithError: error] ;
	}
}




- (void)postToLinkedInStarted:(ASIFormDataRequest *)post
{
	
}

- (void)postToLinkedInFinished:(ASIFormDataRequest *)post
{
	DDLinkedInPostType postType = [[post.userInfo objectForKey: linkedInPostType] intValue] ;
	NSInteger statusCode = [post responseStatusCode] ;
	
	if (statusCode == 201)
	{
		if (delegate && [delegate respondsToSelector: @selector(linkedInPostDidSucceed:)])
			[delegate linkedInPostDidSucceed: postType] ;
	}
	else
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The post to LinkedIn failed"] ;
		if (delegate && [delegate respondsToSelector: @selector(linkedInPost:failedWithError:)])
			[delegate linkedInPost: postType failedWithError: error] ;
	}
	
}

- (void)postToLinkedInFailed:(ASIFormDataRequest *)post
{
	DDLinkedInPostType type = [[post.userInfo objectForKey: linkedInPostType] intValue] ;
	
	NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The post to LinkedIn failed"] ;
	if (delegate && [delegate respondsToSelector: @selector(linkedInPost:failedWithError:)])
		[delegate linkedInPost: type failedWithError: error] ;
}

@end
