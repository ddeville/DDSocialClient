//
//  DDFlickrClient.h
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 8/9/10.
//  Copyright 2010 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDSocialNetworkClient.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"

typedef enum
{
	DDFlickrRequestTypeUnknown,
}
DDFlickrRequestType ;

typedef enum
{
	DDFlickrPostTypeUnknown,
}
DDFlickrPostType ;



@class DDFlickrClient ;


/*
	Protocol definition
 */
@protocol DDFlickrClientDelegate <DDSocialNetworkClientDelegate, NSObject>

@optional
- (void)flickrPostDidSucceedAndReturned:(NSMutableDictionary *)response ;
- (void)flickrPostFailedWithError:(NSError *)error ;
- (void)flickrRequestDidSucceedAndReturned:(NSMutableDictionary *)response ;
- (void)flickrRequestFailedWithError:(NSError *)error ;

@end





@interface DDFlickrClient : DDSocialNetworkClient <ASIHTTPRequestDelegate>
{
	NSString *frob ;
}

@property (getter=delegate,setter=setDelegate,nonatomic,assign) id <DDFlickrClientDelegate> delegate ;
@property (nonatomic, retain) NSString *frob ;


- (void)getUserInfo ;
- (void)postImageToFlickr:(UIImage *)image withTitle:(NSString *)title andDescription:(NSString *)description ;

/*
	NOTE: Galleries are not for adding your own photos
	but other user's photos, for your own photos, use photosets...
	and YES, Flickr is retarded.
 */
- (void)getListOfGalleries ;
- (void)createGallery:(NSString *)galleryName withDescription:(NSString *)description ;
- (void)postImage:(NSString *)imageID toGallery:(NSString *)galleryID withComment:(NSString *)comment ;

// this is to add your own photos
- (void)getListOfPhotosets ;
- (void)createPhotoset:(NSString *)photosetName withDescription:(NSString *)description withPrimaryPhoto:(NSString *)photoID ;
- (void)postImage:(NSString *)imageID toPhotoset:(NSString *)photosetID ;

@end
