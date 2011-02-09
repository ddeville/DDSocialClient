//
//  DDTwitterClient.h
//  SocialNetworkClient
//
//  Created by Damien DeVille on 7/29/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "DDSocialClient.h"
#import "ASIHTTPRequest.h"


@protocol DDTwitterClientDelegate ;

@interface DDTwitterClient : DDSocialClient <ASIHTTPRequestDelegate>
{
	@private
	NSString *initialToken ;
}

@property (getter=delegate,setter=setDelegate,nonatomic,assign) id <DDTwitterClientDelegate> delegate ;

- (id)initWithDelegate:(id <DDTwitterClientDelegate>)theDelegate ;

- (void)postMessageToTwitter:(NSString *)message ;
- (void)postMessageToTwitter:(NSString *)message withURL:(NSString *)URL ;
- (void)postImageToTwitter:(UIImage *)image withMessage:(NSString *)message ;


@end



@protocol DDTwitterClientDelegate <DDSocialClientDelegate, NSObject>

@optional
/*
	Twitter will not request the location if your app does
	not already required it. in case location is not enabled in
	your app, the location will not be enabled in twitter no matter
	what value you return in this method.
 */
- (BOOL)shouldGeolocalizeTweet:(NSString *)tweetMessage ;
- (void)twitterPostDidSucceedAndReturned:(NSMutableDictionary *)response ;
- (void)twitterPostFailedWithError:(NSError *)error ;

@end