//
//  DDFacebookClient.m
//  SocialNetworkClient
//
//  Created by Damien DeVille on 7/29/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import "DDFacebookClient.h"
#import "JSON.h"
#import "ASINetworkQueue.h"
#import "ASIFormDataRequest.h"

#define facebookPostType		@"FacebookPostType"
#define facebookRequestType		@"FacebookRequestType"


@interface DDFacebookClient (Private)

- (void)requestToFacebookStarted:(ASIHTTPRequest *)request ;
- (void)requestToFacebookFinished:(ASIHTTPRequest *)request ;
- (void)requestToFacebookFailed:(ASIHTTPRequest *)request ;

- (void)postToFacebookStarted:(ASIFormDataRequest *)post ;
- (void)postToFacebookFinished:(ASIFormDataRequest *)post ;
- (void)postToFacebookFailed:(ASIFormDataRequest *)post ;

- (void)queuedPostsToFacebookStarted:(ASINetworkQueue *)queue ;
- (void)queuedPostsToFacebookFinished:(ASINetworkQueue *)queue ;
- (void)queuedPostsToFacebookFailed:(ASINetworkQueue *)queue ;

@end


@implementation DDFacebookClient

@dynamic delegate ;

- (id)initWithDelegate:(id <DDFacebookClientDelegate>)theDelegate
{
	if ((self = [super initWithDelegate: theDelegate]))
	{
		[self setDelegate: theDelegate] ;
	}
	
	return self ;
}

- (DDSocialClientType)clientType
{
	return kDDSocialClientFacebook ;
}

+ (NSString *)clientServiceKey
{
	return FACEBOOK_SERVICE_KEY ;
}

+ (NSString *)clientDomain
{
	return FACEBOOK_DOMAIN ;
}

- (NSString *)name
{
	return @"Facebook" ;
}




#pragma mark -
#pragma mark Authentication methods

- (NSString *)authenticationURLString
{
	NSString *authFormatString = @"https://graph.facebook.com/oauth/authorize?client_id=%@&redirect_uri=%@&scope=%@&type=user_agent&display=touch" ;
	/*
		NOTE: this is basically all we need for our purpose.
		in case you need more permissions, check:
		http://developers.facebook.com/docs/authentication/permissions
	 */
	//NSString *requestedPermissions = @"publish_stream" ;
	NSString *requestedPermissions = @"offline_access,publish_stream" ;
	NSString *urlString = [NSString stringWithFormat: authFormatString, FACEBOOK_API_ID, @"http://www.facebook.com/connect/login_success.html", requestedPermissions] ;
	
	return urlString ;
}

- (void)login
{
	if ([FACEBOOK_API_ID length] == 0)
	{
		NSLog(@"You need to specify FACEBOOK_API_ID in DDSocialClient.h") ;
		
		NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 7 userInfo: [NSDictionary dictionaryWithObject: @"Unspecified API key." forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
			[delegate socialClient: self authenticationDidFailWithError: error] ;
		return ;
	}
	
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable)
	{
		NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 1 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because there is no Internet connection." forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
			[delegate socialClient: self authenticationDidFailWithError: error] ;
		return ;
	}
	
	[self showLoginDialog] ;
}

- (NSDictionary *)parseURL:(NSString *)URL
{
	NSRange accessTokenRange = [URL rangeOfString: @"access_token="] ;
	if (accessTokenRange.length > 0)
	{
		NSString *accessToken ;
		int fromIndex = accessTokenRange.location + accessTokenRange.length ;
		accessToken = [URL substringFromIndex: fromIndex] ;
		accessToken = [accessToken stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ;
		NSRange periodRange = [accessToken rangeOfString: @"&"] ;
		accessToken = [accessToken substringToIndex: periodRange.location] ;
		
		// we build a dictionary with the token that we return
		return [NSDictionary dictionaryWithObject: accessToken forKey: @"AccessToken"] ;
	}
	return nil ;
}




#pragma mark -
#pragma mark Get Facebook data methods

- (void)getUserFacebookData
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookRequestUserData] forKey: facebookRequestType]] ;
	[request startAsynchronous] ;
}

- (void)getUserPicture
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/picture?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookRequestUserPicture] forKey: facebookRequestType]] ;
	[request startAsynchronous] ;
}

- (void)getUserFriends
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/friends?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookRequestUserFriends] forKey: facebookRequestType]] ;
	[request startAsynchronous] ;
}

- (void)getUserNewsFeeds
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/home?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookRequestUserNewsFeeds] forKey: facebookRequestType]] ;
	[request startAsynchronous] ;
}

- (void)getUserWallFeeds
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/feed?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookRequestUserWallFeeds] forKey: facebookRequestType]] ;
	[request startAsynchronous] ;
}

- (void)getUserPhotoAlbums
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/albums?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookRequestUserPhotoAlbums] forKey: facebookRequestType]] ;
	[request startAsynchronous] ;
}

- (void)getUserLikes
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/likes?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookRequestUserLikes] forKey: facebookRequestType]] ;
	[request startAsynchronous] ;
}

- (void)getUserGroups
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/groups?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookRequestUserGroups] forKey: facebookRequestType]] ;
	[request startAsynchronous] ;
}

- (void)getUserEvents
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/events?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookRequestUserEvents] forKey: facebookRequestType]] ;
	[request startAsynchronous] ;
}




#pragma mark -
#pragma mark Post data to Facebook methods

- (void)updateFacebookStatus:(NSString *)statusMessage
{
	// if there is no message, no point going further, this is an error
	if (statusMessage == nil || [statusMessage length] == 0)
	{
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to post a status message" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: DDFacebookPostStatusUpdate failedWithError: error] ; 
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	// we can eventually build the POST
	NSURL *url = [NSURL URLWithString:@"https://graph.facebook.com/feed"] ;
	
	ASIFormDataRequest *post = [ASIFormDataRequest requestWithURL: url] ;
	[post setPostValue: token.key forKey: @"access_token"] ;
	[post setPostValue: statusMessage forKey: @"message"] ;
	[post setDidStartSelector: @selector(postToFacebookStarted:)] ;
	[post setDidFinishSelector: @selector(postToFacebookFinished:)] ;
	[post setDidFailSelector: @selector(postToFacebookFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookPostStatusUpdate] forKey: facebookPostType]] ;
	[post startAsynchronous] ;
}

- (void)postPhotoToFacebook:(UIImage *)photoFile withCaption:(NSString *)photoCaption
{
	/*
		NOTE: a FB album will be created for the given app if not already created
	 */
	
	// if there is no photo, no point going further
	if (photoFile == nil)
	{
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to post a photo" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: DDFacebookPostPhotoUpload failedWithError: error] ; 
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSURL *url = [NSURL URLWithString:@"https://graph.facebook.com/me/photos"] ;
	
	ASIFormDataRequest *post = [ASIFormDataRequest requestWithURL: url] ;
	[post setPostValue: token.key forKey: @"access_token"] ;
	[post addData: UIImagePNGRepresentation(photoFile) forKey: @"source"] ;
	if (photoCaption && [photoCaption length])
		[post setPostValue: photoCaption forKey: @"message"] ;
	[post setDidStartSelector: @selector(postToFacebookStarted:)] ;
	[post setDidFinishSelector: @selector(postToFacebookFinished:)] ;
	[post setDidFailSelector: @selector(postToFacebookFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookPostPhotoUpload] forKey: facebookPostType]] ;
	[post startAsynchronous] ;
}

- (void)createFacebookAlbum:(NSString *)albumName withDescription:(NSString *)albumDescription
{
	// if there is no album name, no point going further
	if (albumName == nil || [albumName length] == 0)
	{
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to post an album name" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: DDFacebookPostAlbumCreation failedWithError: error] ; 
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSURL *url = [NSURL URLWithString:@"https://graph.facebook.com/me/albums"] ;
	
	ASIFormDataRequest *post = [ASIFormDataRequest requestWithURL: url] ;
	[post setPostValue: token.key forKey: @"access_token"] ;
	[post setPostValue: albumName forKey: @"name"] ;
	if (albumDescription && [albumDescription length])
		[post setPostValue: albumDescription forKey: @"description"] ;
	[post setDidStartSelector: @selector(postToFacebookStarted:)] ;
	[post setDidFinishSelector: @selector(postToFacebookFinished:)] ;
	[post setDidFailSelector: @selector(postToFacebookFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookPostAlbumCreation] forKey: facebookPostType]] ;
	[post startAsynchronous] ;
}

- (void)postPhoto:(UIImage *)photoFile toAlbum:(NSString *)albumID withCaption:(NSString *)photoCaption
{
	// if there is no photo, no point going further
	if (photoFile == nil)
	{
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to post a photo" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: DDFacebookPostPhotoUpload failedWithError: error] ; 
		return ;
	}
	
	// if no albumID, it is a simple photo posting
	if (albumID == nil || [albumID length] == 0)
	{
		[self postPhotoToFacebook: photoFile withCaption: photoCaption] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSString *URLString = [NSString stringWithFormat: @"http://graph.facebook.com/%@/photos", albumID] ;
	NSURL *url = [NSURL URLWithString: URLString] ;
	
	ASIFormDataRequest *post = [ASIFormDataRequest requestWithURL: url] ;
	[post setPostValue: token.key forKey: @"access_token"] ;
	[post addData: UIImagePNGRepresentation(photoFile) forKey: @"source"] ;
	if (photoCaption && [photoCaption length])
		[post setPostValue: photoCaption forKey: @"message"] ;
	[post setDidStartSelector: @selector(postToFacebookStarted:)] ;
	[post setDidFinishSelector: @selector(postToFacebookFinished:)] ;
	[post setDidFailSelector: @selector(postToFacebookFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookPostPhotoToAlbum] forKey: facebookPostType]] ;
	[post startAsynchronous] ;
}

- (void)postPhotos:(NSArray *)photoArray toAlbum:(NSString *)albumID
{
	// if there are no photos, we return
	if (photoArray == nil || [photoArray count] == 0)
	{
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to post at least one photo" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: DDFacebookPostAlbumCreation failedWithError: error] ; 
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSString *URLString ;
	// we decide the URL to post to in function of if there is an album ID or not
	if (albumID && [albumID length])
		URLString = [NSString stringWithFormat: @"http://graph.facebook.com/%@/photos", albumID] ;
	else
		URLString = @"http://graph.facebook.com/me/photos" ;
	
	// we create an operation queue for uploading the photos
	ASINetworkQueue *networkQueue = [ASINetworkQueue queue] ;
	[networkQueue setRequestDidStartSelector: @selector(queuedPostsToFacebookStarted:)] ;
	[networkQueue setRequestDidFailSelector: @selector(queuedPostsToFacebookFinished:)] ;
	[networkQueue setRequestDidFinishSelector: @selector(queuedPostsToFacebookFailed:)] ;
	if (albumID && [albumID length])
		[networkQueue setUserInfo: [NSDictionary dictionaryWithObject: albumID forKey: @"albumID"]] ;
	[networkQueue setDelegate: self] ;
	
	// we now loop through the photo array and create a post for each photo
	for (id photo in photoArray)
	{
		// we check that we actually have an image
		if (![photo isMemberOfClass: [UIImage class]])
			continue ;
		
		// we create the post
		ASIFormDataRequest *post = [ASIFormDataRequest requestWithURL: [NSURL URLWithString: URLString]] ;
		[post setPostValue: token.key forKey: @"access_token"] ;
		[post addData: UIImagePNGRepresentation((UIImage *)photo) forKey: @"source"] ;
		
		// we add the request to the queue
		[networkQueue addOperation: post] ;
	}
	// we can now start the queue: ..... GOOOOOO!
	[networkQueue go] ;
}

- (void)postLinkToFacebook:(NSString *)linkString withName:(NSString *)linkName withCaption:(NSString *)linkCaption withDescription:(NSString *)linkDescription withMessage:(NSString *)linkMessage withPicture:(NSString *)linkPicture
{
	// if there is no link, no point going further
	if (linkString == nil || [linkString length] == 0)
	{
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to post a link" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: DDFacebookPostLinkPost failedWithError: error] ; 
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSURL *url = [NSURL URLWithString:@"https://graph.facebook.com/me/feed"] ;
	
	ASIFormDataRequest *post = [ASIFormDataRequest requestWithURL: url] ;
	[post setPostValue: token.key forKey: @"access_token"] ;
	[post setPostValue: linkString forKey: @"link"] ;
	if (linkName && [linkName length])
		[post setPostValue: linkName forKey: @"name"] ;
	if (linkCaption && [linkCaption length])
		[post setPostValue: linkCaption forKey: @"caption"] ;
	if (linkDescription && [linkDescription length])
		[post setPostValue: linkDescription forKey: @"description"] ;
	if (linkMessage && [linkMessage length])
		[post setPostValue: linkMessage forKey: @"message"] ;
	if (linkPicture)
		[post setPostValue: linkPicture forKey: @"picture"] ;
	[post setDidStartSelector: @selector(postToFacebookStarted:)] ;
	[post setDidFinishSelector: @selector(postToFacebookFinished:)] ;
	[post setDidFailSelector: @selector(postToFacebookFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookPostLinkPost] forKey: facebookPostType]] ;
	[post startAsynchronous] ;
}

- (void)postNoteToFacebook:(NSString *)noteText withSubjectMessage:(NSString *)subject
{
	// if there is no link, no point going further
	if (noteText == nil || [noteText length] == 0)
	{
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to post a note" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: DDFacebookPostLinkPost failedWithError: error] ; 
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
		return ;
	}
	
	NSURL *url = [NSURL URLWithString:@"https://graph.facebook.com/me/notes"] ;
	
	ASIFormDataRequest *post = [ASIFormDataRequest requestWithURL: url] ;
	[post setPostValue: token.key forKey: @"access_token"] ;
	[post setPostValue: noteText forKey: @"message"] ;
	if (subject && [subject length])
		[post setPostValue: subject forKey: @"subject"] ;
	[post setDidStartSelector: @selector(postToFacebookStarted:)] ;
	[post setDidFinishSelector: @selector(postToFacebookFinished:)] ;
	[post setDidFailSelector: @selector(postToFacebookFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFacebookPostNotePost] forKey: facebookPostType]] ;
	[post startAsynchronous] ;
}




#pragma mark -
#pragma mark Connection and parsing methods

- (void)requestToFacebookStarted:(ASIHTTPRequest *)request
{
	
}

- (void)requestToFacebookFinished:(ASIHTTPRequest *)request
{
	NSString *responseString = [request responseString] ;
	NSMutableDictionary *responseJSON = [responseString JSONValue] ;
	
	// we can now call our delegate with the response for the given request
	DDFacebookRequestType requestType = [[request.userInfo objectForKey: facebookRequestType] intValue] ;
	
	// we simply check if there response is an error
	if ([responseJSON objectForKey: @"error"])
	{
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 4 userInfo: [NSDictionary dictionaryWithObject: [[responseJSON objectForKey: @"error"] objectForKey: @"message"] forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookRequest:failedWithError:)])
			[delegate facebookRequest: requestType failedWithError: error] ;
	}
	else
	{
		if (delegate && [delegate respondsToSelector: @selector(facebookGotResponse:forRequestType:)])
			[delegate facebookGotResponse: responseJSON forRequestType: requestType] ;
	}
}

- (void)requestToFacebookFailed:(ASIHTTPRequest *)request
{
	// we can now call our delegate with the response for the given request
	DDFacebookRequestType requestType = [[request.userInfo objectForKey: facebookRequestType] intValue] ;
	
	NSError *error ;
	if ([[request.error domain] isEqualToString: @"ASIHTTPRequestErrorDomain"] && [request.error code] == 2)
		error = [NSError errorWithDomain: DDSocialClientError code: 2 userInfo: [NSDictionary dictionaryWithObject: @"The request timed out." forKey: NSLocalizedDescriptionKey]] ;
	else
		error = [NSError errorWithDomain: DDSocialClientError code: 0 userInfo: [NSDictionary dictionaryWithObject: @"Unknown error." forKey: NSLocalizedDescriptionKey]] ;
	if (delegate && [delegate respondsToSelector: @selector(facebookRequest:failedWithError:)])
		[delegate facebookRequest: requestType failedWithError: error] ;
}

- (void)postToFacebookStarted:(ASIFormDataRequest *)post
{
	
}

- (void)postToFacebookFinished:(ASIFormDataRequest *)post
{
	NSString *responseString = [post responseString] ;
	NSMutableDictionary *responseJSON = [responseString JSONValue] ;
	
	// we can now call our delegate with the response for the given request
	DDFacebookPostType postType = [[post.userInfo objectForKey: facebookPostType] intValue] ;
	
	// we simply check if there response is an error
	if ([responseJSON objectForKey: @"error"])
	{
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 4 userInfo: [NSDictionary dictionaryWithObject: [[responseJSON objectForKey: @"error"] objectForKey: @"message"] forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: postType failedWithError: error] ;
	}
	else
	{
		if (delegate && [delegate respondsToSelector: @selector(facebookPostDidSucceed:andReturned:)])
			[delegate facebookPostDidSucceed: postType andReturned:responseJSON] ;
	}
}

- (void)postToFacebookFailed:(ASIFormDataRequest *)post
{
	// we can now call our delegate with the response for the given request
	DDFacebookPostType postType = [[post.userInfo objectForKey: facebookPostType] intValue] ;
	
	NSError *error ;
	if ([[post.error domain] isEqualToString: @"ASIHTTPRequestErrorDomain"] && [post.error code] == 2)
		error = [NSError errorWithDomain: DDSocialClientError code: 2 userInfo: [NSDictionary dictionaryWithObject: @"The request timed out." forKey: NSLocalizedDescriptionKey]] ;
	else
		error = [NSError errorWithDomain: DDSocialClientError code: 0 userInfo: [NSDictionary dictionaryWithObject: @"Unknown error." forKey: NSLocalizedDescriptionKey]] ;
	if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
		[delegate facebookPost: postType failedWithError: error] ;
}

- (void)queuedPostsToFacebookStarted:(ASINetworkQueue *)queue
{
	
}

- (void)queuedPostsToFacebookFinished:(ASINetworkQueue *)queue
{
	if (delegate && [delegate respondsToSelector: @selector(facebookPostDidSucceed:andReturned:)])
		[delegate facebookPostDidSucceed: DDFacebookPostArrayOfPhotos andReturned: nil] ;
}

- (void)queuedPostsToFacebookFailed:(ASINetworkQueue *)queue
{
	NSError *error = [NSError errorWithDomain: DDSocialClientError code: 0 userInfo: [NSDictionary dictionaryWithObject: @"Unknown error." forKey: NSLocalizedDescriptionKey]] ;
	if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
		[delegate facebookPost: DDFacebookPostArrayOfPhotos failedWithError: error] ;
}

@end
