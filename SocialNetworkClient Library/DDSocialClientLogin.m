//
//  DDSocialClientLogin.m
//  SocialNetworkClient
//
//  Created by Damien DeVille on 7/27/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import "DDSocialClientLogin.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+Pulse.h"

#define CONTENT_INSET	10.0f

@interface DDSocialClientLogin (Private)

- (void)findAndResignFirstResponder:(UIView *)aView ;
- (void)setOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated ;
- (void)cancelButtonTapped:(id)sender ;
- (void)checkForAccessToken:(NSString *)urlString ;

@end


@implementation DDSocialClientLogin

@synthesize requestURL ;

- (id)initWithURL:(NSURL *)aRequestURL delegate:(id<DDSocialClientLoginDelegate>)aDelegate
{
	if (self = [super init])
	{
		requestURL = [aRequestURL retain] ;
		delegate = aDelegate ;
		
		[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications] ;
		[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(orientationChanged:) name: UIDeviceOrientationDidChangeNotification object: nil] ;
		
		// make sure we resign the current first responder (in case there is a keyboard for example)
		UIWindow *window = [UIApplication sharedApplication].keyWindow ;
		[self findAndResignFirstResponder: window] ;
	}
	
	return self ;
}

- (void)dealloc
{
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications] ;
	[[NSNotificationCenter defaultCenter] removeObserver: self] ;
	
	if (firstResponder)
		[firstResponder becomeFirstResponder] ;
	[firstResponder release], firstResponder = nil ;
	
	[requestURL release], requestURL = nil ;
	
	[super dealloc] ;
}

- (void)viewDidLoad
{
	[super viewDidLoad] ;
	
	// add the view to the whole window and set its background to transparent
	UIWindow *window = [UIApplication sharedApplication].keyWindow ;
	[self.view setFrame: window.frame] ;
	[self.view setBackgroundColor: [UIColor clearColor]] ;
	
	// create a content view with rounder corner
	contentView = [[UIView alloc] init] ;
	[contentView setBackgroundColor: [UIColor colorWithWhite: 0.55f alpha: 0.9f]] ;
	[contentView.layer setCornerRadius: 12.0f] ;
	[self.view addSubview: contentView] ;
	[contentView release] ;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		// if we are on the iPad, manually set the size and center
		[contentView setFrame: CGRectMake(0.0f, 0.0f, 380.0f, 500.0f)] ;
		[contentView setCenter: window.center] ;
	}
	else
	{
		// if we are on the iPhone, inset the content frame from the application frame
		CGRect appFrame = [UIScreen mainScreen].applicationFrame ;
		appFrame = CGRectInset(appFrame, CONTENT_INSET, CONTENT_INSET) ;
		[contentView setFrame: appFrame] ;
	}
	
	// add a bar at the top of the content view
	UIView *bar = [[UIView alloc] initWithFrame: CGRectMake(10.0f, 10.0f, contentView.frame.size.width-20.0f, 26.0f)] ;
	[bar setBackgroundColor: [UIColor darkGrayColor]] ;
	[bar setAutoresizingMask: UIViewAutoresizingFlexibleWidth] ;
	[contentView addSubview: bar] ;
	[bar release] ;
	
	// get the service name from the delegate
	NSString *name ;
	if (delegate && [delegate respondsToSelector: @selector(serviceName)])
		name = [delegate serviceName] ;
	
	// add the service logo to the left of the bar
	UIImageView *logo = [[UIImageView alloc] initWithImage: [UIImage imageNamed: [NSString stringWithFormat: @"%@.png", name]]] ;
	[logo setCenter: CGPointMake(15.0f, 13.0f)] ;
	[bar addSubview: logo] ;
	[logo release] ;
	
	// add an activity indicator to the right of the bar
	activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle: UIActivityIndicatorViewStyleWhite] ;
	[activityIndicator setAutoresizingMask: UIViewAutoresizingFlexibleLeftMargin] ;
	[activityIndicator setCenter: CGPointMake(bar.frame.size.width-45.0f, 13.0f)] ;
	[bar addSubview: activityIndicator] ;
	[activityIndicator release] ;
	
	// add the service login title to the bar
	UILabel *barTitle = [[UILabel alloc] initWithFrame: CGRectMake(30.0f, 0.0f, 150.0f, 26.0f)] ;
	[barTitle setText: [NSString stringWithFormat: @"%@ Login", name]] ;
	[barTitle setTextColor: [UIColor whiteColor]] ;
	[barTitle setFont: [UIFont boldSystemFontOfSize: 15.0f]] ;
	[barTitle setBackgroundColor: [UIColor clearColor]] ;
	[barTitle setTextAlignment: UITextAlignmentLeft] ;
	[bar addSubview: barTitle] ;
	[barTitle release] ;
	
	 // add a close button to the right of the bar
	UIButton *close = [UIButton buttonWithType: UIButtonTypeCustom] ;
	[close setFrame: CGRectMake(0.0f, 0.0f, 44.0f, 44.0f)] ;
	[close setAutoresizingMask: UIViewAutoresizingFlexibleLeftMargin] ;
	[close setImage: [UIImage imageNamed: @"close.png"] forState: UIControlStateNormal] ;
	[close setCenter: CGPointMake(bar.frame.size.width-17.0f, 14.0f)] ;
	[close addTarget: self action: @selector(cancelButtonTapped:) forControlEvents: UIControlEventTouchUpInside] ;
	[close setShowsTouchWhenHighlighted: YES] ;
	[bar addSubview: close] ;
	
	// we finally add a web view where we will display the login stuff in
	webView = [[UIWebView alloc] initWithFrame: CGRectMake(10.0f, 36.0f, contentView.frame.size.width-20.0f, contentView.frame.size.height-46.0f)] ;
	[webView setAutoresizingMask: UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight] ;
	[webView setDelegate: self] ;
	[contentView addSubview: webView] ;
	[webView release] ;
	
	[activityIndicator startAnimating] ;
}

- (void)viewDidUnload
{
	[super viewDidUnload] ;
}

- (void)setRequestURL:(NSURL *)aURL
{
	[aURL retain] ;
	[requestURL release] ;
	requestURL = aURL ;
	
	NSURLRequest *request = [NSURLRequest requestWithURL: requestURL] ;
	[webView loadRequest: request] ;
}

- (void)presentAnimated:(BOOL)animated
{
	// we get the key window and add the view to it
	UIWindow *window = [UIApplication sharedApplication].keyWindow ;
	[window addSubview: self.view] ;
	
	// set the original orientation without animating
	[self setOrientation: [[UIApplication sharedApplication] statusBarOrientation] animated: NO] ;
	
	// fade the background in
	if (animated)
	{
		[UIView beginAnimations: @"FadeBackgroundIn" context: nil] ;
		[UIView setAnimationDuration: 0.35f] ;
		[UIView setAnimationDelegate: self] ;
		[UIView setAnimationDidStopSelector: @selector(animationInDidStop:finished:context:)] ;
	}
	
	[self.view setBackgroundColor: [UIColor colorWithWhite: 0.0f alpha: 0.6f]] ;
	
	if (animated)
	{
		[UIView commitAnimations] ;
		[contentView pulse] ;
	}
	else
	{
		NSURLRequest *request = [NSURLRequest requestWithURL: requestURL] ;
		[webView loadRequest: request] ;
	}
}

- (void)animationInDidStop:(NSString *)animationID finished:(BOOL)finished context:(void *)context
{
	// now that the animation has stopped, load the URL request in the web view
	NSURLRequest *request = [NSURLRequest requestWithURL: requestURL] ;
	[webView loadRequest: request] ;
}

- (void)dismissAnimated:(BOOL)animated
{
	// we simply fade the whole view out when dismissing
	if (animated)
	{
		[UIView beginAnimations: @"ViewStyleDown" context: nil] ;
		[UIView setAnimationDuration: 0.35f] ;
		[UIView setAnimationDelegate: self] ;
		[UIView setAnimationDidStopSelector: @selector(animationOutDidStop:finished:context:)] ;
	}
	
	[self.view setAlpha: 0.0f] ;
	
	if (animated)
	{
		[UIView commitAnimations] ;
	}
	else
	{
		[self.view removeFromSuperview] ;
		
		if (delegate && [delegate respondsToSelector: @selector(socialClientLoginDidDismiss:)])
			[delegate socialClientLoginDidDismiss: self] ;
	}
}

- (void)animationOutDidStop:(NSString *)animationID finished:(BOOL)finished context:(void *)context
{
	// now that the animation finished we can remove the view and give a shout to the delegate
	[self.view removeFromSuperview] ;
	
	if (delegate && [delegate respondsToSelector: @selector(socialClientLoginDidDismiss:)])
		[delegate socialClientLoginDidDismiss: self] ;
}

- (void)findAndResignFirstResponder:(UIView *)view
{
	// loop recursively through all the view subviews
	for (UIView *subView in [view subviews])
	{
		// check is the current subview is the first responder
		if ([subView isFirstResponder])
		{
			// in that case, we keep a pointer to it
			firstResponder = [subView retain] ;
			// we resign it
			[firstResponder resignFirstResponder] ;
			break ;
		}
		[self findAndResignFirstResponder: subView] ;
	}
}

- (void)orientationChanged:(NSNotification *)notification
{
	// we get the interface orientation from the status bar orientation
	UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation] ;
	[self setOrientation: interfaceOrientation animated: YES] ;
}

- (void)setOrientation:(UIInterfaceOrientation)orientation animated:(BOOL)animated
{
	static UIInterfaceOrientation lastOrientation ;
	
	if (animated)
	{
		[UIView beginAnimations: @"ContentViewRotation" context: nil] ;
		
		// determine the duration of the animation according to the last and next orientations and the device type
		NSTimeInterval duration = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 0.4f : 0.3f ;
		if ((UIInterfaceOrientationIsPortrait(orientation) && UIInterfaceOrientationIsPortrait(lastOrientation)) || (UIInterfaceOrientationIsLandscape(orientation) && UIInterfaceOrientationIsLandscape(lastOrientation)))
			duration *= 2 ;
		[UIView setAnimationDuration: duration] ;
	}
	
	lastOrientation = orientation ;
	
	CGRect frame = [[UIScreen mainScreen] applicationFrame] ;
	
	// in case we are on the iPhone, we need to resize the content view
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		CGRect bounds = contentView.bounds ;
		bounds.size.width = UIInterfaceOrientationIsPortrait(orientation) ? frame.size.width - 2*CONTENT_INSET : (frame.size.height + 0.5f * frame.origin.y) - 2*CONTENT_INSET ;
		bounds.size.height = UIInterfaceOrientationIsPortrait(orientation) ? frame.size.height - 2*CONTENT_INSET : frame.size.width - 2*CONTENT_INSET ;
		[contentView setBounds: bounds] ;
	}
	
	// update the center (will change in case the status bar is visible)
	CGPoint center ;
	center.x = 0.5f * (frame.size.width + frame.origin.x) + 0.5f * frame.origin.x ;
	center.y = 0.5f * (frame.size.height + frame.origin.y) + 0.5f * frame.origin.y ;
	contentView.center = center ;
	
	// finally rotate the content view (no need to rotate the whole screen view)
	switch (orientation)
	{
		case UIDeviceOrientationPortrait:
			contentView.transform = CGAffineTransformIdentity ;
			break ;
		case UIDeviceOrientationLandscapeLeft:
			contentView.transform = CGAffineTransformMakeRotation(0.5*M_PI) ;
			break ;
		case UIDeviceOrientationLandscapeRight:
			contentView.transform = CGAffineTransformMakeRotation(-0.5*M_PI) ;
			break ;
		case UIDeviceOrientationPortraitUpsideDown:
			contentView.transform = CGAffineTransformMakeRotation(-M_PI) ;
			break ;
		default:
			break ;
	}
	
	// in case we want it animated, commit the animation
	if (animated)
		[UIView commitAnimations] ;
}

- (void)cancelButtonTapped:(id)sender
{
	// simply give a shout to the delegate
	if (delegate && [delegate respondsToSelector: @selector(closeTapped:)])
		[delegate closeTapped: self] ;
}

- (void)checkForAccessToken:(NSString *)urlString
{
	// we ask the delegate to parse this one itself
	NSDictionary *responseDictionary ;
	if (delegate && [delegate respondsToSelector: @selector(pleaseParseThisURLResponseForMe:)])
		responseDictionary = [delegate pleaseParseThisURLResponseForMe: urlString] ;
	
	if (responseDictionary)
	{
		NSString *accessToken = nil ;
		if (accessToken = [responseDictionary objectForKey: @"AccessToken"])
		{
			/*
				NOTE: we create a token and return it. for now, we do not set
				the service, the client will do it itself when it receives it
			 */
			
			OAuthToken *token = [[[OAuthToken alloc] initWithService: nil andKey: accessToken andSecret: @"NoSecretForThisClient"] autorelease] ;
			if (delegate && [delegate respondsToSelector: @selector(oAuthTokenFound:)])
				[delegate oAuthTokenFound: token] ;
		}
		
		// for some clients, we have a temporary token that needs to be validated
		if ([responseDictionary objectForKey: @"TempOAuthToken"])
		{
			if (delegate && [delegate respondsToSelector: @selector(validateOAuthToken:withIdentifier:)])
				[delegate validateOAuthToken: [responseDictionary objectForKey: @"TempOAuthToken"] withIdentifier: [responseDictionary objectForKey: @"TempOAuthIdentifier"]] ;
		}
	}
}



#pragma mark -
#pragma mark UIWebView delegate methods

- (BOOL)webView:(UIWebView *)aWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSString *urlString = request.URL.absoluteString ;
	[self checkForAccessToken: urlString] ;
	
	return YES ;
}

- (void)webViewDidStartLoad:(UIWebView *)aWebView
{
	[activityIndicator startAnimating] ;
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView
{
	[activityIndicator stopAnimating] ;
}



#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning] ;
}

@end
