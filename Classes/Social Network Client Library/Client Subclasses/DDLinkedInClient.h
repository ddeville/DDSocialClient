//
//  DDLinkedInClient.h
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 11/11/10.
//  Copyright 2010 Acrossair. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDSocialNetworkClient.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"



typedef enum
{
	DDLinkedInPostMessage,
	DDLinkedInPostLink,
	DDLinkedInPostMessageAndLink,
}
DDLinkedInPostType ;



@class DDLinkedInClient ;

/*
	Protocol definition
 */
@protocol DDLinkedInClientDelegate <DDSocialNetworkClientDelegate, NSObject>

@optional

- (void)linkedInPostDidSucceed:(DDLinkedInPostType)type ;
- (void)linkedInPost:(DDLinkedInPostType)type failedWithError:(NSError *)error ;

@end





@interface DDLinkedInClient : DDSocialNetworkClient <ASIHTTPRequestDelegate>
{
@private
	NSString *initialToken ;
	NSString *initialTokenSecret ;
}

@property (getter=delegate,setter=setDelegate,nonatomic,assign) id <DDLinkedInClientDelegate> delegate ;


- (id)initWithDelegate:(id <DDLinkedInClientDelegate>)theDelegate ;

- (void)postMessage:(NSString *)message visibilityConnectionsOnly:(BOOL)connectionsOnly ;
- (void)postLinkWithTitle:(NSString *)linkTitle andLink:(NSString *)URL andLinkImage:(NSString *)imageURL andLinkDescription:(NSString *)description visibilityConnectionsOnly:(BOOL)connectionsOnly ;
- (void)postMessage:(NSString *)message withLinkTitle:(NSString *)linkTitle andLink:(NSString *)URL andLinkImage:(NSString *)imageURL andLinkDescription:(NSString *)description visibilityConnectionsOnly:(BOOL)connectionsOnly ;


@end
