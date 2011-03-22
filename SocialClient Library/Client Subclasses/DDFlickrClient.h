//
//  DDFlickrClient.h
//  SocialNetworkClient
//
//  Created by Damien DeVille on 8/9/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDSocialClient.h"
#import "ASIHTTPRequest.h"

typedef enum
{
	DDFlickrRequestTypeUnknown,
	DDFlickrRequestTypeFrob,
	DDFlickrRequestTypeToken,
	DDFlickrRequestTypeUserInfo,
	DDFlickrRequestTypeGalleryList,
	DDFlickrRequestTypePhotoSetList,
}
DDFlickrRequestType ;

typedef enum
{
	DDFlickrPostTypeUnknown,
	DDFlickrPostTypeImage,
	DDFlickrPostTypeCreateGallery,
	DDFlickrPostTypeImageGallery,
	DDFlickrPostTypeCreatePhotoSet,
	DDFlickrPostTypeImagePhotoSet,
}
DDFlickrPostType ;


@class DDFlickrClient ;

@protocol DDFlickrClientDelegate <NSObject, DDSocialClientDelegate>

@optional
- (void)flickrPost:(DDFlickrPostType)postType didSucceedAndReturned:(NSMutableDictionary *)response ;
- (void)flickrPost:(DDFlickrPostType)postType failedWithError:(NSError *)error ;
- (void)flickrRequest:(DDFlickrRequestType)requestType didSucceedAndReturned:(NSMutableDictionary *)response ;
- (void)flickrRequest:(DDFlickrRequestType)requestType failedWithError:(NSError *)error ;

@end

@interface DDFlickrClient : DDSocialClient <ASIHTTPRequestDelegate>
{
@private
	NSString *frob ;
}

@property (nonatomic,assign) id <DDFlickrClientDelegate> delegate ;

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
