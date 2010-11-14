//
//  DDSocialNetworkClient.h
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 7/27/10.
//  Copyright 2010 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDSocialNetworkClientLoginDialog.h"
#import "OAuthToken.h"
#import "ASINetworkQueue.h"



#define FACEBOOK_DOMAIN			@"facebook.com"
#define TWITTER_DOMAIN			@"twitter.com"
#define FLICKR_DOMAIN			@"flickr.com"
#define LINKEDIN_DOMAIN			@"linkedin.com"

#define FACEBOOK_SERVICE_KEY	@"Facebook"
#define TWITTER_SERVICE_KEY		@"Twitter"
#define FLICKR_SERVICE_KEY		@"Flickr"
#define LINKEDIN_SERVICE_KEY	@"LinkedIn"

/*
	NOTE: You will need to change these ones to
	match your application details.
 */
#define FACEBOOK_API_ID			@"nil"


#define TWITTER_API_KEY			@"nil"
#define TWITTER_CONSUMER_KEY	@"nil"
#define TWITTER_CONSUMER_SECRET	@"nil"

#define BIT_LY_LOGIN			@"nil"
#define BIT_LY_API_KEY			@"nil"

#define TWITPIC_API_KEY			@"nil"


#define FLICKR_API_KEY			@"nil"
#define FLICKR_API_SECRET		@"nil"


#define LINKEDIN_API_KEY		@"nil"
#define LINKEDIN_API_SECRET		@"nil"


typedef enum
{
	kDDSocialNetworkClientTypeUnknown,
	kDDSocialNetworkClientTypeFacebook,
	kDDSocialNetworkClientTypeTwitter,
	kDDSocialNetworkClientTypeFlickr,
	kDDSocialNetworkClientTypeLinkedIn,
	kDDSocialNetworkClientTypeFoursquare,
}
DDSocialNetworkClientType ;



@class DDSocialNetworkClient ;


/*
	Protocol definition
 */
@protocol DDSocialNetworkClientDelegate <NSObject>

@required
- (BOOL)shouldDisplayLoginDialogForSocialMediaClient:(DDSocialNetworkClient *)client ;
- (UIViewController *)rootViewControllerForDisplayingLoginDialogForSocialMediaClient:(DDSocialNetworkClient *)client ;

@optional
- (void)socialMediaClientAuthenticationDidSucceed:(DDSocialNetworkClient *)client ;
- (void)socialMediaClient:(DDSocialNetworkClient *)client authenticationDidFailWithError:(NSError *)error ;

@end






@interface DDSocialNetworkClient : NSObject <DDSocialNetworkClientLoginDialogDelegate>
{
	id delegate ;
	
	OAuthToken *token ;
	
	DDSocialNetworkClientLoginDialog *loginDialog ;
}

@property (getter=delegate,setter=setDelegate,nonatomic, assign) id <DDSocialNetworkClientDelegate> delegate ;
@property (nonatomic, retain) OAuthToken *token ;

- (id)initWithDelegate:(id<DDSocialNetworkClientDelegate>)thisDelegate ;
- (DDSocialNetworkClientType)clientType ;
+ (NSString *)clientServiceKey ;
+ (NSString *)clientDomain ;
- (NSString *)name ;

// OAuth authentication related methods
+ (BOOL)serviceHasValidToken ;
- (BOOL)serviceHasValidToken ;
+ (void)logout ;
- (NSString *)authenticationURLString ;
- (void)startLoginProcess ;
- (void)showLoginDialog ;


// NSError generation
+ (NSError *)generateErrorWithMessage:(NSString *)errorMessage ;

@end
