//
//  DDSkyrockClient.h
//  DDSocialTest
//
//  Created by Pascal Costa-Cunha on 09/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "DDSocialClient.h"
#import "ASIHTTPRequest.h"

#define SKYROCK_CONSUMER_KEY @""
#define SKYROCK_CONSUMER_SECRET @""


@protocol DDSkyrockClientDelegate <NSObject, DDSocialClientDelegate>

@optional

-(void) SkyrockClientUserData:(NSDictionary*)userData;
-(void) SkyrockClientUserDataFailedWithError:(NSError*)error;

-(void) SkyrockClientUpdateStatusSucceed;
-(void) SkyrockClientUpdateStatusFailedWithError:(NSError*)error;

-(void) SkyrockClientPostProfilePhotoSucceed;
-(void) SkyrockClientPostProfilePhotoFailedWithError:(NSError*)error;

-(void) SkyrockClientPostBlogPhotoSucceedWithURL:(NSString*)urlStr;
-(void) SkyrockClientPostBlogPhotoFailedWithError:(NSError*)error;

-(void) SkyrockClientPostBlogArticleSucceedWithURL:(NSString*)urlStr;
-(void) SkyrockClientPostBlogArticleFailedWithError:(NSError*)error;


@end






@interface DDSkyrockClient : DDSocialClient <ASIHTTPRequestDelegate>

@property (nonatomic,assign) id<DDSkyrockClientDelegate> delegate;

-(id) initWithDelegate:(id<DDSkyrockClientDelegate>)theDelegate;


// title can be nil but neither image nor text
-(void) postBlogPhoto:(UIImage*)image withTitle:(NSString*)title;
-(void) postBlogArticle:(NSString*)text withTitle:(NSString*)title;
-(void) postProfilePhoto:(UIImage*)image;
-(void) updateStatus:(NSString*)text;
-(void) getUserData;


// to use to sign request for other SkyrockAPI request
-(NSString*) oauthHeaderForUrl:(NSString*)url isPost:(BOOL)post postParams:(NSDictionary*)postParams;


@end



