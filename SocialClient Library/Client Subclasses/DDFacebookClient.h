//
//  DDFacebookClient.h
//  SocialNetworkClient
//
//  Created by Damien DeVille on 7/29/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDSocialClient.h"
#import "ASIHTTPRequest.h"

typedef enum
{
	DDFacebookRequestUnknownType,
	DDFacebookRequestUserData,
	DDFacebookRequestUserPicture,
	DDFacebookRequestUserFriends,
	DDFacebookRequestUserNewsFeeds,
	DDFacebookRequestUserWallFeeds,
	DDFacebookRequestUserPhotoAlbums,
	DDFacebookRequestUserLikes,
	DDFacebookRequestUserGroups,
	DDFacebookRequestUserEvents,
}
DDFacebookRequestType ;

typedef enum
{
	DDFacebookPostUnknownType,
	DDFacebookPostStatusUpdate,
	DDFacebookPostPhotoUpload,
	DDFacebookPostAlbumCreation,
	DDFacebookPostPhotoToAlbum,
	DDFacebookPostArrayOfPhotos,
	DDFacebookPostLinkPost,
	DDFacebookPostNotePost,
}
DDFacebookPostType ;


@protocol DDFacebookClientDelegate ;

@interface DDFacebookClient : DDSocialClient <ASIHTTPRequestDelegate>
{
	
}

@property (getter=delegate,setter=setDelegate,nonatomic,assign) id <DDFacebookClientDelegate> delegate ;

- (id)initWithDelegate:(id <DDFacebookClientDelegate>)theDelegate ;


/*
	NOTE: this particular Facebook subclass defines new methods
	that are proper to Facebook but cannot be shared with other
	subclasses issued from the same parent class.
	they are the following
 */

- (void)getUserFacebookData ;
- (void)getUserPicture ;
- (void)getUserFriends ;
- (void)getUserNewsFeeds ;
- (void)getUserWallFeeds ;
- (void)getUserPhotoAlbums ;
- (void)getUserLikes ;
- (void)getUserGroups ;
- (void)getUserEvents ;

- (void)updateFacebookStatus:(NSString *)statusMessage ;
- (void)postPhotoToFacebook:(UIImage *)photoFile withCaption:(NSString *)photoCaption ;
- (void)createFacebookAlbum:(NSString *)albumName withDescription:(NSString *)albumDescription ;
- (void)postPhoto:(UIImage *)photoFile toAlbum:(NSString *)albumID withCaption:(NSString *)photoCaption ;
- (void)postPhotos:(NSArray *)photoArray toAlbum:(NSString *)albumID ;
- (void)postLinkToFacebook:(NSString *)linkString withName:(NSString *)linkName withCaption:(NSString *)linkCaption withDescription:(NSString *)linkDescription withMessage:(NSString *)linkMessage withPicture:(NSString *)linkPicture ;
- (void)postNoteToFacebook:(NSString *)noteText withSubjectMessage:(NSString *)subject ;


@end



@protocol DDFacebookClientDelegate <DDSocialClientDelegate, NSObject>

@optional
- (void)facebookGotResponse:(NSMutableDictionary *)response forRequestType:(DDFacebookRequestType)requestType ;
- (void)facebookRequest:(DDFacebookRequestType)requestType failedWithError:(NSError *)error ;
- (void)facebookPostDidSucceed:(DDFacebookPostType)postType andReturned:(NSMutableDictionary *)response ;
- (void)facebookPost:(DDFacebookPostType)postType failedWithError:(NSError *)error ;

@end