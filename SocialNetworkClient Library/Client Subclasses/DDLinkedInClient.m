//
//  DDLinkedInClient.m
//  SocialNetworkClient
//
//  Created by Damien DeVille on 11/11/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import "DDLinkedInClient.h"
#import "OAuthSign.h"
#import "JSON.h"
#import "ASIFormDataRequest.h"

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

- (DDSocialClientType)clientType
{
	return kDDSocialClientLinkedIn ;
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

- (void)login
{
	if ([LINKEDIN_API_KEY length] == 0 || [LINKEDIN_API_SECRET length] == 0)
	{
		NSLog(@"You need to specify LINKEDIN_API_KEY and LINKEDIN_API_SECRET in DDSocialClient.h") ;
		
		NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 7 userInfo: [NSDictionary dictionaryWithObject: @"Unspecified consumer key and consumer secret." forKey: NSLocalizedDescriptionKey]] ;
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
	
	[self asynchronousRequestInitialLinkedInToken] ;
	[self showLoginDialog] ;
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
			// we have got what we are looking for, start parsing it
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
	[OAuthToken deleteTokenForService: [[self class] clientServiceKey]] ;
	
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
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to post a message" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(linkedInPost:failedWithError:)])
			[delegate linkedInPost: DDLinkedInPostMessage failedWithError: error] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
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
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to post a title and a link" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(linkedInPost:failedWithError:)])
			[delegate linkedInPost: DDLinkedInPostLink failedWithError: error] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
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
	if ((message == nil || [message length] == 0) && (linkTitle == nil || [linkTitle length] == 0) && (URL == nil || [URL length] == 0))
	{
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to post a message or a title" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(linkedInPost:failedWithError:)])
			[delegate linkedInPost: DDLinkedInPostMessageAndLink failedWithError: error] ;
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
		[self login] ;
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
			// dismiss the login dialog
			[loginDialog dismissAnimated: YES] ;
			
			// we send a shout to the delegate that the authentication failed
			NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 5 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the initial token failed." forKey: NSLocalizedDescriptionKey]] ;
			if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
				[delegate socialClient: self authenticationDidFailWithError: error] ;
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
			// dismiss the login dialog
			[loginDialog dismissAnimated: YES] ;
			
			// we send a shout to the delegate that the authentication failed
			NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 5 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the initial token failed." forKey: NSLocalizedDescriptionKey]] ;
			if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
				[delegate socialClient: self authenticationDidFailWithError: error] ;
		}
	}
	else if ([requestType isEqualToString: @"validationTokenRequest"])
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
			
			if (theToken)
			{
				// we create a token, and store it
				OAuthToken *newToken = [[[OAuthToken alloc] initWithService: [[self class] clientServiceKey] andKey: theToken andSecret: theTokenSecret] autorelease] ;
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

- (void)requestToLinkedInFailed:(ASIHTTPRequest *)request
{
	NSString *requestType = [request.userInfo objectForKey: linkedInRequestType] ;
	
	if ([requestType isEqualToString: @"initialTokenRequest"] || [requestType isEqualToString: @"validationTokenRequest"])
	{
		// dismiss the login dialog
		[loginDialog dismissAnimated: YES] ;
		
		// we send a shout to the delegate that the authentication failed
		NSError *error ;
		if ([[request.error domain] isEqualToString: @"ASIHTTPRequestErrorDomain"] && [request.error code] == 2)
			error = [NSError errorWithDomain: DDAuthenticationError code: 2 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request timed out." forKey: NSLocalizedDescriptionKey]] ;
		else if ([requestType isEqualToString: @"initialTokenRequest"])
			error = [NSError errorWithDomain: DDAuthenticationError code: 5 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the initial token failed." forKey: NSLocalizedDescriptionKey]] ;
		else if ([requestType isEqualToString: @"validationTokenRequest"])
			error = [NSError errorWithDomain: DDAuthenticationError code: 6 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the OAuth token failed." forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
			[delegate socialClient: self authenticationDidFailWithError: error] ;
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
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 4 userInfo: [NSDictionary dictionaryWithObject: @"The post failed." forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(linkedInPost:failedWithError:)])
			[delegate linkedInPost: postType failedWithError: error] ;
	}
	
}

- (void)postToLinkedInFailed:(ASIFormDataRequest *)post
{
	DDLinkedInPostType type = [[post.userInfo objectForKey: linkedInPostType] intValue] ;
	
	NSError *error ;
	if ([[post.error domain] isEqualToString: @"ASIHTTPRequestErrorDomain"] && [post.error code] == 2)
		error = [NSError errorWithDomain: DDSocialClientError code: 2 userInfo: [NSDictionary dictionaryWithObject: @"The request timed out." forKey: NSLocalizedDescriptionKey]] ;
	else
		error = [NSError errorWithDomain: DDSocialClientError code: 0 userInfo: [NSDictionary dictionaryWithObject: @"Unknown error." forKey: NSLocalizedDescriptionKey]] ;
	if (delegate && [delegate respondsToSelector: @selector(linkedInPost:failedWithError:)])
		[delegate linkedInPost: type failedWithError: error] ;
}

@end
