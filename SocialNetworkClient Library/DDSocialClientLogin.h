//
//  DDSocialClientLogin.h
//  SocialNetworkClient
//
//  Created by Damien DeVille on 7/27/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DDSocialClientLoginDelegate ;
@class OAuthToken ;

@interface DDSocialClientLogin : UIViewController <UIWebViewDelegate>
{
	id<DDSocialClientLoginDelegate> delegate ;
	
	@private
	UIResponder *firstResponder ;
	UIView *contentView ;
	NSURL *requestURL ;
	UIWebView *webView ;
	UIActivityIndicatorView *activityIndicator ;
}

@property (nonatomic,assign) id<DDSocialClientLoginDelegate> delegate ;
@property (nonatomic,retain) NSURL *requestURL ;

- (id)initWithURL:(NSURL *)aRequestURL delegate:(id<DDSocialClientLoginDelegate>)aDelegate ;
- (void)presentAnimated:(BOOL)animated ;
- (void)dismissAnimated:(BOOL)animated ;

@end


@protocol DDSocialClientLoginDelegate <NSObject>

@required
- (void)oAuthTokenFound:(OAuthToken *)accessToken ;
- (NSString *)serviceName ;
- (NSDictionary *)parseURL:(NSString *)URL ;
@optional
- (void)validateOAuthToken:(NSString *)tempOAuthToken withIdentifier:(NSString *)tempOAuthIdentifier ;
- (void)closeTapped:(DDSocialClientLogin *)loginVC ;
- (void)socialClientLoginDidDismiss:(DDSocialClientLogin *)loginVC ;

@end