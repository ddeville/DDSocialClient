//
//  DDSocialNetworkClient.m
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 7/27/10.
//  Copyright 2010 Damien DeVille. All rights reserved.
//

#import "DDSocialNetworkClient.h"


@interface DDSocialNetworkClient (Private)

@end





@implementation DDSocialNetworkClient

@synthesize delegate ;
@synthesize token ;


- (id)initWithDelegate:(id<DDSocialNetworkClientDelegate>)thisDelegate
{
	if(self = [super init])
	{
		[self setDelegate: thisDelegate] ;
	}
	
	return self ;
}



- (DDSocialNetworkClientType)clientType
{
	return kDDSocialNetworkClientTypeUnknown ;
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
	/*
		NOTE: in case the token is not valid we might want to delete
		it from the user defaults here...
	 */
	
	if (self.token = [OAuthToken tokenForService: [[self class] clientServiceKey]])
		return YES ;
	return NO ;
}


+ (void)logout
{
	[OAuthToken deleteTokenFromUserDefaultsForService: [self clientServiceKey]] ;
	
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
- (void)startLoginProcess
{
	
}



- (void)showLoginDialog
{
	/*
		NOTE: since we deal a lot with asynchronous request, we never really know
		where we come from so to be safe, we switch to the main thread
	 */
	if (![NSThread mainThread])
		[self performSelectorOnMainThread: @selector(showLoginDialog) withObject: nil waitUntilDone: YES] ;
	
	if ([delegate shouldDisplayLoginDialogForSocialMediaClient: self])
	{
		loginDialog = [[DDSocialNetworkClientLoginDialog alloc] initWithURL: [self authenticationURLString] delegate: self] ;
		
		// we get the root window from the application delegate
		UIViewController *delegateRootViewController = [delegate rootViewControllerForDisplayingLoginDialogForSocialMediaClient: self] ;
		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			[loginDialog setModalPresentationStyle: UIModalPresentationFormSheet] ;
			[loginDialog setModalTransitionStyle: UIModalTransitionStyleFlipHorizontal] ;
		}
		
		[delegateRootViewController presentModalViewController: loginDialog animated: YES] ;
		[loginDialog release] ;
	}
}

















#pragma mark -
#pragma mark Actual message posting methods


/*
	NOTE: since each client has different requirements
	when it comes to accessing and posting data, the best
	bet here is to leave each subclass taking care of it.
 */
















#pragma mark -
#pragma mark DDSocialNetworkClientLoginDialog delegate methods

- (void)oAuthTokenFound:(OAuthToken *)accessToken
{
	// we first set the service in the token in case this has not been done earlier
	[accessToken setService: [[self class] clientServiceKey]] ;
	
	// and we store it
	[self setToken: accessToken] ;
	[accessToken storeToUserDefaults] ;
	
	// we can tell the delegate the authentication worked
	if(delegate && [delegate respondsToSelector: @selector(socialMediaClientAuthenticationDidSucceed:)])
		[delegate socialMediaClientAuthenticationDidSucceed: self] ;
	
	// and we can close the dialog now
	[loginDialog dismissModalViewControllerAnimated: YES] ;
}



- (void)closeTapped
{
	// we dismiss the view controller here
	[loginDialog dismissModalViewControllerAnimated: YES] ;
	
	/*
		In function of the value of the token here, we can deduce
		if the login worked or not.
	 */
	
	if ([self serviceHasValidToken])
	{
		if(delegate && [delegate respondsToSelector: @selector(socialMediaClientAuthenticationDidSucceed:)])
			[delegate socialMediaClientAuthenticationDidSucceed: self] ;
	}
	else
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The authentication failed"] ;
		if (delegate && [delegate respondsToSelector: @selector(socialMediaClient:authenticationDidFailWithError:)])
			[delegate socialMediaClient: self authenticationDidFailWithError: error] ;
	}
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












#pragma mark -
#pragma mark NSError definition class methods

+ (NSError *)generateErrorWithMessage:(NSString *)errorMessage
{
	NSDictionary *infoDictionary = [NSDictionary dictionaryWithObject: errorMessage forKey: @"info"] ;
	NSString *appDomain = [[NSBundle mainBundle] bundleIdentifier] ;
	
	return [NSError errorWithDomain: appDomain code: 69 userInfo: infoDictionary] ;
}




@end
