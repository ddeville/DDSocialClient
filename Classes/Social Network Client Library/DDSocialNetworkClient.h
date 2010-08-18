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


#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 40000
#define RUNNING_IOS4_0_OR_GREATER
#endif




#define FACEBOOK_DOMAIN @"facebook.com"
#define TWITTER_DOMAIN @"twitter.com"
#define FLICKR_DOMAIN @"flickr.com"

#define FACEBOOK_SERVICE_KEY @"Facebook"
#define TWITTER_SERVICE_KEY @"Twitter"
#define FLICKR_SERVICE_KEY @"Flickr"

/*
	NOTE: You will need to change these ones to
	match your application details.
 */
#define FACEBOOK_API_ID @"980b3a83f198c37d82ce902994825078"


#define TWITTER_API_KEY @"t4epogUsHIqCGHxe33wEhw"
#define TWITTER_CONSUMER_KEY @"t4epogUsHIqCGHxe33wEhw"
#define TWITTER_CONSUMER_SECRET @"cRMUiWDefQpgN7VuhPqdig0qU1LqsDFs0ZiZxgLy4Ro"

#define BIT_LY_LOGIN @"acrossair"
#define BIT_LY_API_KEY @"R_4bea911bf467b617965f8ebf0f2af305"

#define TWITPIC_API_KEY @"4417a2db5d5174150bcbf6830d8f11d3"


#define FLICKR_API_KEY @"9685d96872ec4bbed722ae03b73685f0"
#define FLICKR_API_SECRET @"96c157dc50ade3e1"



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
