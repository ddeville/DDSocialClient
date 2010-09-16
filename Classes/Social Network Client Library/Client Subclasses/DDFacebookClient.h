//
//  DDFacebookClient.h
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 7/29/10.
//  Copyright 2010 Damien DeVille. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDSocialNetworkClient.h"
#import "ASIHTTPRequest.h"
#import "ASIFormDataRequest.h"


typedef enum
{
	AAFacebookRequestUnknownType,
	AAFacebookRequestUserData,
	AAFacebookRequestUserPicture,
	AAFacebookRequestUserFriends,
	AAFacebookRequestUserNewsFeeds,
	AAFacebookRequestUserWallFeeds,
	AAFacebookRequestUserPhotoAlbums,
	AAFacebookRequestUserLikes,
	AAFacebookRequestUserGroups,
	AAFacebookRequestUserEvents,
}
AAFacebookRequestType ;


typedef enum
{
	AAFacebookPostUnknownType,
	AAFacebookPostStatusUpdate,
	AAFacebookPostPhotoUpload,
	AAFacebookPostAlbumCreation,
	AAFacebookPostPhotoToAlbum,
	AAFacebookPostArrayOfPhotos,
	AAFacebookPostLinkPost,
	AAFacebookPostNotePost,
}
AAFacebookPostType ;





@class DDFacebookClient ;


/*
	Protocol definition
 */
@protocol DDFacebookClientDelegate <DDSocialNetworkClientDelegate, NSObject>

@optional
- (void)facebookGotResponse:(NSMutableDictionary *)response forRequestType:(AAFacebookRequestType)requestType ;
- (void)facebookRequest:(AAFacebookRequestType)requestType failedWithError:(NSError *)error ;
- (void)facebookPostDidSucceed:(AAFacebookPostType)postType andReturned:(NSMutableDictionary *)response ;
- (void)facebookPost:(AAFacebookPostType)postType failedWithError:(NSError *)error ;

@end





@interface DDFacebookClient : DDSocialNetworkClient <ASIHTTPRequestDelegate>
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
