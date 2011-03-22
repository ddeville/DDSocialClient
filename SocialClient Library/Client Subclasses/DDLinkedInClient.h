//
//  DDLinkedInClient.h
//  SocialNetworkClient
//
//  Created by Damien DeVille on 11/11/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDSocialClient.h"
#import "ASIHTTPRequest.h"

typedef enum
{
	DDLinkedInPostMessage,
	DDLinkedInPostLink,
	DDLinkedInPostMessageAndLink,
}
DDLinkedInPostType ;


@class DDLinkedInClient ;

@protocol DDLinkedInClientDelegate <NSObject, DDSocialClientDelegate>

@optional
- (void)linkedInPostDidSucceed:(DDLinkedInPostType)type ;
- (void)linkedInPost:(DDLinkedInPostType)type failedWithError:(NSError *)error ;

@end

@interface DDLinkedInClient : DDSocialClient <ASIHTTPRequestDelegate>
{
	@private
	NSString *initialToken ;
	NSString *initialTokenSecret ;
}

@property (nonatomic,assign) id <DDLinkedInClientDelegate> delegate ;

- (id)initWithDelegate:(id <DDLinkedInClientDelegate>)theDelegate ;

- (void)postMessage:(NSString *)message visibilityConnectionsOnly:(BOOL)connectionsOnly ;
- (void)postLinkWithTitle:(NSString *)linkTitle andLink:(NSString *)URL andLinkImage:(NSString *)imageURL andLinkDescription:(NSString *)description visibilityConnectionsOnly:(BOOL)connectionsOnly ;
- (void)postMessage:(NSString *)message withLinkTitle:(NSString *)linkTitle andLink:(NSString *)URL andLinkImage:(NSString *)imageURL andLinkDescription:(NSString *)description visibilityConnectionsOnly:(BOOL)connectionsOnly ;


@end
