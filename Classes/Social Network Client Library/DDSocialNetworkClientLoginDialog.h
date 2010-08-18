//
//  DDSocialNetworkClientLoginDialog.h
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 7/27/10.
//  Copyright 2010 Damien DeVille. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "OAuthToken.h"


@protocol DDSocialNetworkClientLoginDialogDelegate <NSObject>

@required
- (void)oAuthTokenFound:(OAuthToken *)accessToken ;
- (void)closeTapped ;
- (NSString *)serviceName ;
- (NSDictionary *)pleaseParseThisURLResponseForMe:(NSString *)response ;

@optional
- (void)validateOAuthToken:(NSString *)tempOAuthToken withIdentifier:(NSString *)tempOAuthIdentifier ;

@end



@interface DDSocialNetworkClientLoginDialog : UIViewController <UIWebViewDelegate>
{
	/*
		NOTE: you might want to change UIToolBar here to match
		your app style.
		I recommend you leave the UIBarButtonItem as a Cancel button
		since the UIWebView will dismiss itself when the login is done
		and clicking this button is actually cancelling the login.
	 */
	UIToolbar *toolbar ;
	UIBarButtonItem *cancelButton ;
	
	id <DDSocialNetworkClientLoginDialogDelegate> delegate ;
	NSString *requestURL ;
	UIWebView *webView ;
}


- (id)initWithURL:(NSString *)thisRequestURL delegate:(id<DDSocialNetworkClientLoginDialogDelegate>)thisDelegate ;
- (void)cancelButtonTapped:(id)sender ;
- (void)checkForAccessToken:(NSString *)urlString ;


@end
