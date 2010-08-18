//
//  DDSocialNetworkClientLoginDialog.m
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 7/27/10.
//  Copyright 2010 Damien DeVille. All rights reserved.
//

#import "DDSocialNetworkClientLoginDialog.h"



@implementation DDSocialNetworkClientLoginDialog


- (id)initWithURL:(NSString *)thisRequestURL delegate:(id<DDSocialNetworkClientLoginDialogDelegate>)thisDelegate
{
	if (self = [super init])
	{
		requestURL = thisRequestURL ;
		delegate = thisDelegate ;
	}
	
	return self ;
}




- (void)viewDidLoad
{
	[super viewDidLoad] ;
	
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		[self.view setFrame: CGRectMake(0.0f, 0.0f, 540.0f, 620.0f)] ;
	else
		[self.view setFrame: CGRectMake(0.0f, 0.0f, 320.0f, 460.0f)] ;
	
	[self.view setBackgroundColor: [UIColor lightGrayColor]] ;
	
	// we add a tool bar with buttons to close the view when we are done
	toolbar = [[UIToolbar alloc] initWithFrame: CGRectMake(0.0f, 0.0f, self.view.frame.size.width, 44.0f)] ;
	[toolbar setAutoresizingMask: UIViewAutoresizingFlexibleWidth] ;
	[toolbar setBarStyle: UIBarStyleBlack] ;
	[self.view addSubview: toolbar] ;
	[toolbar release] ;
	
	// we add the buttons to the tool bar
	NSString *barTitleString ;
	UIFont *thisFont = [UIFont boldSystemFontOfSize: 20.0f] ;
	if (delegate && [delegate respondsToSelector: @selector(serviceName)])
		barTitleString = [NSString stringWithFormat: @"%@ Login", [delegate serviceName]] ;
	else
		barTitleString = @"Login" ;
	CGSize textSize = [barTitleString sizeWithFont: thisFont constrainedToSize: CGSizeMake(200.0f, 30.0f) lineBreakMode: UILineBreakModeTailTruncation] ;
	UILabel *barTitle = [[[UILabel alloc] initWithFrame: CGRectMake(0.0f, 0.0f, textSize.width, 30.0f)] autorelease] ;
	[barTitle setText: barTitleString] ;
	[barTitle setTextColor: [UIColor whiteColor]] ;
	[barTitle setFont: thisFont] ;
	[barTitle setBackgroundColor: [UIColor clearColor]] ;
	[barTitle setTextAlignment: UITextAlignmentCenter] ;
	UIBarButtonItem *titleButton = [[[UIBarButtonItem alloc] initWithCustomView: barTitle] autorelease] ;
	cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemCancel target: self action: @selector(cancelButtonTapped:)] ;
	UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem: UIBarButtonSystemItemFlexibleSpace target: nil action: nil] ;
	[toolbar setItems: [NSArray arrayWithObjects: flexibleSpace, flexibleSpace, titleButton, flexibleSpace, cancelButton, nil]] ;
	[flexibleSpace release] ;
	[cancelButton release] ;
	
	
	
	// we add a web view where we will display the login stuff in
	webView = [[UIWebView alloc] initWithFrame: CGRectMake(0.0f, 44.0f, self.view.frame.size.width, self.view.frame.size.height-44.0f)] ;
	[webView setDelegate: self] ;
	[self.view addSubview: webView] ;
	[webView release] ;
	
	[webView loadRequest: [NSURLRequest requestWithURL: [NSURL URLWithString: @"about:blank"]]] ;
	
	NSURL *url = [NSURL URLWithString: requestURL] ;
	NSURLRequest *request = [NSURLRequest requestWithURL: url] ;
	[webView loadRequest: request];
	
}



- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		return YES ;
	
	return (interfaceOrientation == UIInterfaceOrientationPortrait) ;
}






- (void)cancelButtonTapped:(id)sender
{
	//[self dismissModalViewControllerAnimated: YES] ;
	
	// OR
	
	[delegate closeTapped] ;
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
			{
				[delegate oAuthTokenFound: token] ;
			}
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

- (BOOL)webView:(UIWebView *)thisWebView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	NSString *urlString = request.URL.absoluteString ;
	[self checkForAccessToken: urlString] ;
	
	return TRUE ;
}










- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning] ;
}



- (void)viewDidUnload
{
	[super viewDidUnload] ;
}



- (void)dealloc
{
	[super dealloc] ;
}


@end
