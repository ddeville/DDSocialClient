//
//  DDSocialClient.m
//  SocialNetworkClient
//
//  Created by Damien DeVille on 7/27/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import "DDSocialClient.h"
#import "ASINetworkQueue.h"

@implementation DDSocialClient

@synthesize delegate ;
@synthesize token ;

- (id)initWithDelegate:(id<DDSocialClientDelegate>)aDelegate
{
	if(self = [super init])
	{
		[self setDelegate: aDelegate] ;
		[[Reachability reachabilityForInternetConnection] startNotifier] ;
	}
	
	return self ;
}

- (void)dealloc
{
	[token release], token = nil ;
	
	[super dealloc] ;
}

- (DDSocialClientType)clientType
{
	return kDDSocialClientUnknown ;
}

+ (NSString *)clientServiceKey
{
	return nil ;
}

+ (NSString *)clientDomain
{
	return nil ;
}

- (NSString *)name
{
	return nil ;
}



#pragma mark -
#pragma mark OAuth authentication related methods

+ (BOOL)serviceHasValidToken
{
	if ([OAuthToken tokenForService: [[self class] clientServiceKey]])
		return YES ;
	return NO ;
}

- (BOOL)serviceHasValidToken
{
	// Watch, the token is also assigned here!
	if (self.token = [OAuthToken tokenForService: [[self class] clientServiceKey]])
		return YES ;
	return NO ;
}

+ (void)logout
{
	[OAuthToken deleteTokenForService: [self clientServiceKey]] ;
	
	// we remove the cookies for the current service
	NSString *serviceCookieDomain = [self clientDomain] ;
	
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

/*
	Each subclass HAS TO implement this method in order
	to return the correct URL string for performing the authentication
 */
- (NSString *)authenticationURLString
{
	return nil ;
}

/*
	NOTE: the main purpose of this method comes from the fact that some clients
	(like Twitter or Flickr) require the client to request a request token even
	before displaying the login page.
	since we do not want to freeze the UI while waiting the login page to come up,
	we have to request this token asynchronously.
	this method starts this process and call itself the login dialog when it is ready
	
	the subclasses should implement this method in order to fit to their own requirements
 */
- (void)login
{
	
}

- (void)showLoginDialog
{
	/*
		NOTE: since we deal a lot with asynchronous request, we never really know
		where we come from so to be safe, we switch to the main thread
	 */
	if (![NSThread mainThread])
	{
		[self performSelectorOnMainThread: @selector(showLoginDialog) withObject: nil waitUntilDone: YES] ;
		return ;
	}
	
	if (loginDialog)
	{
		// update the login dialog by loading a new URL request
		NSURL *URL = [NSURL URLWithString: [self authenticationURLString]] ;
		[loginDialog setRequestURL: URL] ;
		return ;
	}
	
	// check whether the delegate blocks the login dialog, display an authentication error in that case
	if (delegate && [delegate respondsToSelector: @selector(shouldDisplayLoginForSocialClient:)])
	{
		if ([delegate shouldDisplayLoginForSocialClient: self] == NO)
		{
			NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the login dialog could not be displayed." forKey: NSLocalizedDescriptionKey]] ;
			if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
				[delegate socialClient: self authenticationDidFailWithError: error] ;
			return ;
		}
	}
	
	// no block from the delegate, show the login dialog
	NSURL *URL = [NSURL URLWithString: [self authenticationURLString]] ;
	loginDialog = [[DDSocialClientLogin alloc] initWithURL: URL delegate: self] ;
	
	[loginDialog presentAnimated: YES] ;
}




#pragma mark -
#pragma mark Actual message posting methods


/*
	NOTE: since each client has different requirements
	when it comes to accessing and posting data, the best
	bet here is to leave each subclass take care of it.
 */



#pragma mark -
#pragma mark DDSocialNetworkClientLoginDialog delegate methods

- (void)oAuthTokenFound:(OAuthToken *)accessToken
{
	// we first set the service in the token in case this has not been done earlier
	[accessToken setService: [[self class] clientServiceKey]] ;
	
	// and we store it
	[self setToken: accessToken] ;
	[accessToken store] ;
	
	// we can tell the delegate the authentication worked
	if(delegate && [delegate respondsToSelector: @selector(socialClientAuthenticationDidSucceed:)])
		[delegate socialClientAuthenticationDidSucceed: self] ;
	
	// and we can close the dialog now
	[loginDialog dismissAnimated: YES] ;
}

- (void)closeTapped:(DDSocialClientLogin *)loginVC
{
	// we dismiss the view controller here
	[loginDialog dismissAnimated: YES] ;
	
	/*
		In function of the value of the token here, we can deduce
		if the login worked or not.
	 */
	
	if ([self serviceHasValidToken])
	{
		if(delegate && [delegate respondsToSelector: @selector(socialClientAuthenticationDidSucceed:)])
			[delegate socialClientAuthenticationDidSucceed: self] ;
	}
	else
	{
		NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 4 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the user closed the login dialog." forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
			[delegate socialClient: self authenticationDidFailWithError: error] ;
	}
}

- (void)socialClientLoginDidDismiss:(DDSocialClientLogin *)loginVC
{
	[loginDialog release] ;
	loginDialog = nil ;
	
	// tell the delegate about it
	if (delegate && [delegate respondsToSelector: @selector(didDismissLoginForSocialClient:)])
		[delegate didDismissLoginForSocialClient: self] ;
}

- (NSString *)serviceName
{
	return [[self class] clientServiceKey] ;
}

/*
	NOTE: given that the way access tokens are returned by the server
	are different for each client, each subclass has to implement its
	own version of this one
 */
- (NSDictionary *)pleaseParseThisURLResponseForMe:(NSString *)response
{
	// Go fuck yourself, I'll tell my subclass to do it ;)
	return nil ;
}

- (void)validateOAuthToken:(NSString *)tempOAuthToken withIdentifier:(NSString *)tempOAuthIdentifier
{
	
}

@end
