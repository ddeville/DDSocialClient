//
//  DDFacebookClient.m
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 7/29/10.
//  Copyright 2010 Damien DeVille. All rights reserved.
//

#import "DDFacebookClient.h"
#import "JSON.h"


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


- (id)initWithDelegate:(id <DDFacebookClientDelegate>)theDelegate
{
	if (self = [super initWithDelegate: theDelegate])
	{
		[self setDelegate: theDelegate] ;
	}
	
	return self ;
}



- (DDSocialNetworkClientType)clientType
{
	return kDDSocialNetworkClientTypeFacebook ;
}



+ (NSString *)clientServiceKey
{
	return FACEBOOK_SERVICE_KEY ;
}



+ (NSString *)clientDomain
{
	return FACEBOOK_DOMAIN ;
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



- (void)startLoginProcess
{
	// in the case of Facebook, the login process starts with showing the login dialog
	[self showLoginDialog] ;
}



- (NSDictionary *)pleaseParseThisURLResponseForMe:(NSString *)response
{
	/*
		NOTE: there are 2 versions to find the token in the string here:
			- an elegant one involving the fresh new NSRegularExpression introduced in iOS 3.2
			- an ugly one that simply does the job for whichever version of iOS...
		
		we should add a check for device system version here and select the right one,
		but hey, that will come...
	 */
	
	
	/*
	NSError *error ;
	NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern: @"access_token=(.*)&" options: 0 error: &error] ;
	if (regex != nil)
	{
		NSTextCheckingResult *firstMatch = [regex firstMatchInString: urlString options: 0 range: NSMakeRange(0, [urlString length])] ;
		if (firstMatch)
		{
			NSString *accessToken ;
			NSRange accessTokenRange = [firstMatch rangeAtIndex: 1] ;
			accessToken = [urlString substringWithRange: accessTokenRange] ;
			accessToken = [accessToken stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ;
			
			// we print the token and tell the delegate about it
			NSLog(@"token:  %@", accessToken) ;
			[delegate oAuthTokenFound: accessToken] ;
		}
	}
	 */

	
	NSRange accessTokenRange = [response rangeOfString: @"access_token="] ;
	if (accessTokenRange.length > 0)
	{
		NSString *accessToken ;
		int fromIndex = accessTokenRange.location + accessTokenRange.length ;
		accessToken = [response substringFromIndex: fromIndex] ;
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
		[self startLoginProcess] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: @"userDataRequest" forKey: @"whichRequest"]] ;
	[request startAsynchronous] ;
}



- (void)getUserPicture
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/picture?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: @"userPictureRequest" forKey: @"whichRequest"]] ;
	[request startAsynchronous] ;
}



- (void)getUserFriends
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/friends?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: @"userFriendsRequest" forKey: @"whichRequest"]] ;
	[request startAsynchronous] ;
}



- (void)getUserNewsFeeds
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/home?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: @"userNewsFeedsRequest" forKey: @"whichRequest"]] ;
	[request startAsynchronous] ;
}



- (void)getUserWallFeeds
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/feed?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: @"userWallFeedsRequest" forKey: @"whichRequest"]] ;
	[request startAsynchronous] ;
}



- (void)getUserPhotoAlbums
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/albums?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: @"userPhotoAlbums" forKey: @"whichRequest"]] ;
	[request startAsynchronous] ;
}



- (void)getUserLikes
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/likes?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: @"userLikesRequest" forKey: @"whichRequest"]] ;
	[request startAsynchronous] ;
}



- (void)getUserGroups
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/groups?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: @"userGroupsRequest" forKey: @"whichRequest"]] ;
	[request startAsynchronous] ;
}



- (void)getUserEvents
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSString *URLFormat = @"https://graph.facebook.com/me/events?access_token=%@" ;
	NSString *URLString = [NSString stringWithFormat: URLFormat, [token.key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URLString]] ;
	[request setDidStartSelector: @selector(requestToFacebookStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFacebookFinished:)] ;
	[request setDidFailSelector: @selector(requestToFacebookFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: @"userEventsRequest" forKey: @"whichRequest"]] ;
	[request startAsynchronous] ;
}











#pragma mark -
#pragma mark Post data to Facebook methods

- (void)updateFacebookStatus:(NSString *)statusMessage
{
	// if there is no message, no point going further, this is an error
	if (statusMessage == nil || [statusMessage length] == 0)
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to post a status message"] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: AAFacebookPostStatusUpdate failedWithError: error] ; 
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
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
	[post setUserInfo: [NSDictionary dictionaryWithObject: @"statusUpdate" forKey: @"whichPost"]] ;
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
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to post a photo"] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: AAFacebookPostPhotoUpload failedWithError: error] ; 
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
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
	[post setUserInfo: [NSDictionary dictionaryWithObject: @"photoUpload" forKey: @"whichPost"]] ;
	[post startAsynchronous] ;
}



- (void)createFacebookAlbum:(NSString *)albumName withDescription:(NSString *)albumDescription
{
	// if there is no album name, no point going further
	if (albumName == nil || [albumName length] == 0)
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to post an album name"] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: AAFacebookPostAlbumCreation failedWithError: error] ; 
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
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
	[post setUserInfo: [NSDictionary dictionaryWithObject: @"albumCreation" forKey: @"whichPost"]] ;
	[post startAsynchronous] ;
}



- (void)postPhoto:(UIImage *)photoFile toAlbum:(NSString *)albumID withCaption:(NSString *)photoCaption
{
	// if there is no photo, no point going further
	if (photoFile == nil)
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to post a photo"] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: AAFacebookPostPhotoUpload failedWithError: error] ; 
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
		[self startLoginProcess] ;
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
	[post setUserInfo: [NSDictionary dictionaryWithObject: @"photoUploadToAlbum" forKey: @"whichPost"]] ;
	[post startAsynchronous] ;
}



- (void)postPhotos:(NSArray *)photoArray toAlbum:(NSString *)albumID
{
	// if there are no photos, we return
	if (photoArray == nil || [photoArray count] == 0)
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to post at least one photo"] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: AAFacebookPostAlbumCreation failedWithError: error] ; 
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
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
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to post a link"] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: AAFacebookPostLinkPost failedWithError: error] ; 
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
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
	[post setUserInfo: [NSDictionary dictionaryWithObject: @"linkPost" forKey: @"whichPost"]] ;
	[post startAsynchronous] ;
}



- (void)postNoteToFacebook:(NSString *)noteText withSubjectMessage:(NSString *)subject
{
	// if there is no link, no point going further
	if (noteText == nil || [noteText length] == 0)
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to post a note"] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: AAFacebookPostLinkPost failedWithError: error] ; 
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
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
	[post setUserInfo: [NSDictionary dictionaryWithObject: @"notePost" forKey: @"whichPost"]] ;
	[post startAsynchronous] ;
}

























#pragma mark -
#pragma mark Connection and parsing methods


- (void)requestToFacebookStarted:(ASIHTTPRequest *)request
{
	NSLog(@"started request...") ;
}


- (void)requestToFacebookFinished:(ASIHTTPRequest *)request
{
	NSLog(@"started parsing request...") ;
	
	NSString *responseString = [request responseString] ;
	NSMutableDictionary *responseJSON = [responseString JSONValue] ;
	
	// we can now call our delegate with the response for the given request
	NSString *requestType = [request.userInfo objectForKey: @"whichRequest"] ;
	AAFacebookRequestType facebookRequestType ;
	if ([requestType isEqualToString: @"userDataRequest"])
		facebookRequestType = AAFacebookRequestUserData ;
	else if ([requestType isEqualToString: @"userPictureRequest"])
		facebookRequestType = AAFacebookRequestUserPicture ;
	else if ([requestType isEqualToString: @"userFriendsRequest"])
		facebookRequestType = AAFacebookRequestUserFriends ;
	else if ([requestType isEqualToString: @"userNewsFeedsRequest"])
		facebookRequestType = AAFacebookRequestUserNewsFeeds ;
	else if ([requestType isEqualToString: @"userWallFeedsRequest"])
		facebookRequestType = AAFacebookRequestUserWallFeeds ;
	else if ([requestType isEqualToString: @"userPhotoAlbums"])
		facebookRequestType = AAFacebookRequestUserPhotoAlbums ;
	else if ([requestType isEqualToString: @"userLikesRequest"])
		facebookRequestType = AAFacebookRequestUserLikes ;
	else if ([requestType isEqualToString: @"userGroupsRequest"])
		facebookRequestType = AAFacebookRequestUserGroups ;
	else if ([requestType isEqualToString: @"userEventsRequest"])
		facebookRequestType = AAFacebookRequestUserEvents ;
	else
		facebookRequestType = AAFacebookRequestUnknownType ;
	
	// we simply check if there response is an error
	if ([responseJSON objectForKey: @"error"])
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: [[responseJSON objectForKey: @"error"] objectForKey: @"message"]] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookRequest:failedWithError:)])
			[delegate facebookRequest: facebookRequestType failedWithError: error] ;
	}
	else
	{
		if (delegate && [delegate respondsToSelector: @selector(facebookGotResponse:forRequestType:)])
			[delegate facebookGotResponse: responseJSON forRequestType: facebookRequestType] ;
	}
}



- (void)requestToFacebookFailed:(ASIHTTPRequest *)request
{
	NSLog(@"request failed...") ;
	
	// we can now call our delegate with the response for the given request
	NSString *requestType = [request.userInfo objectForKey: @"whichRequest"] ;
	AAFacebookRequestType facebookRequestType ;
	if ([requestType isEqualToString: @"userDataRequest"])
		facebookRequestType = AAFacebookRequestUserData ;
	else if ([requestType isEqualToString: @"userPictureRequest"])
		facebookRequestType = AAFacebookRequestUserPicture ;
	else if ([requestType isEqualToString: @"userFriendsRequest"])
		facebookRequestType = AAFacebookRequestUserFriends ;
	else if ([requestType isEqualToString: @"userNewsFeedsRequest"])
		facebookRequestType = AAFacebookRequestUserNewsFeeds ;
	else if ([requestType isEqualToString: @"userWallFeedsRequest"])
		facebookRequestType = AAFacebookRequestUserWallFeeds ;
	else if ([requestType isEqualToString: @"userPhotoAlbums"])
		facebookRequestType = AAFacebookRequestUserPhotoAlbums ;
	else if ([requestType isEqualToString: @"userLikesRequest"])
		facebookRequestType = AAFacebookRequestUserLikes ;
	else if ([requestType isEqualToString: @"userGroupsRequest"])
		facebookRequestType = AAFacebookRequestUserGroups ;
	else if ([requestType isEqualToString: @"userEventsRequest"])
		facebookRequestType = AAFacebookRequestUserEvents ;
	else
		facebookRequestType = AAFacebookRequestUnknownType ;
	
	NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The request to Facebook failed"] ;
	if (delegate && [delegate respondsToSelector: @selector(facebookRequest:failedWithError:)])
		[delegate facebookRequest: facebookRequestType failedWithError: error] ;
}



- (void)postToFacebookStarted:(ASIFormDataRequest *)post
{
	NSLog(@"started post...") ;
}



- (void)postToFacebookFinished:(ASIFormDataRequest *)post
{
	NSLog(@"post finished...") ;
	
	NSString *responseString = [post responseString] ;
	NSMutableDictionary *responseJSON = [responseString JSONValue] ;
	
	// we can now call our delegate with the response for the given request
	NSString *postType = [post.userInfo objectForKey: @"whichPost"] ;
	AAFacebookPostType facebookPostType ;
	if ([postType isEqualToString: @"statusUpdate"])
		facebookPostType = AAFacebookPostStatusUpdate ;
	else if ([postType isEqualToString: @"photoUpload"])
		facebookPostType = AAFacebookPostPhotoUpload ;
	else if ([postType isEqualToString: @"albumCreation"])
		facebookPostType = AAFacebookPostAlbumCreation ;
	else if ([postType isEqualToString: @"photoUploadToAlbum"])
		facebookPostType = AAFacebookPostPhotoToAlbum ;
	else if ([postType isEqualToString: @"linkPost"])
		facebookPostType = AAFacebookPostLinkPost ;
	else if ([postType isEqualToString: @"notePost"])
		facebookPostType = AAFacebookPostNotePost ;
	else
		facebookPostType = AAFacebookPostUnknownType ;
	
	// we simply check if there response is an error
	if ([responseJSON objectForKey: @"error"])
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: [[responseJSON objectForKey: @"error"] objectForKey: @"message"]] ;
		if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
			[delegate facebookPost: facebookPostType failedWithError: error] ;
	}
	else
	{
		if (delegate && [delegate respondsToSelector: @selector(facebookPostDidSucceed:andReturned:)])
			[delegate facebookPostDidSucceed: facebookPostType andReturned:responseJSON] ;
	}
}



- (void)postToFacebookFailed:(ASIFormDataRequest *)post
{
	NSLog(@"post failed...") ;
	
	// we can now call our delegate with the response for the given request
	NSString *postType = [post.userInfo objectForKey: @"whichPost"] ;
	AAFacebookPostType facebookPostType ;
	if ([postType isEqualToString: @"statusUpdate"])
		facebookPostType = AAFacebookPostStatusUpdate ;
	else if ([postType isEqualToString: @"photoUpload"])
		facebookPostType = AAFacebookPostPhotoUpload ;
	else if ([postType isEqualToString: @"albumCreation"])
		facebookPostType = AAFacebookPostAlbumCreation ;
	else if ([postType isEqualToString: @"photoUploadToAlbum"])
		facebookPostType = AAFacebookPostPhotoToAlbum ;
	else if ([postType isEqualToString: @"linkPost"])
		facebookPostType = AAFacebookPostLinkPost ;
	else if ([postType isEqualToString: @"notePost"])
		facebookPostType = AAFacebookPostNotePost ;
	else
		facebookPostType = AAFacebookPostUnknownType ;
	
	NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The post to Facebook failed"] ;
	if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
		[delegate facebookPost: facebookPostType failedWithError: error] ;
}



- (void)queuedPostsToFacebookStarted:(ASINetworkQueue *)queue
{
	NSLog(@"queued posts started...") ;
}



- (void)queuedPostsToFacebookFinished:(ASINetworkQueue *)queue
{
	NSLog(@"queued posts finished...") ;
	
	if (delegate && [delegate respondsToSelector: @selector(facebookPostDidSucceed:andReturned:)])
		[delegate facebookPostDidSucceed: AAFacebookPostArrayOfPhotos andReturned: nil] ;
}



- (void)queuedPostsToFacebookFailed:(ASINetworkQueue *)queue
{
	NSLog(@"queued posts failed...") ;
	
	NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The queued posts to Facebook failed"] ;
	if (delegate && [delegate respondsToSelector: @selector(facebookPost:failedWithError:)])
		[delegate facebookPost: AAFacebookPostArrayOfPhotos failedWithError: error] ;
}





@end
