//
//  DDFlickrClient.m
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 8/9/10.
//  Copyright 2010 Damien DeVille. All rights reserved.
//

#import "DDFlickrClient.h"
#import "NSString+MD5.h"
#import "JSON.h"

#define flickrPostType		@"FlickrPostType"
#define flickrRequestType	@"FlickrRequestType"




@interface DDFlickrClient (Private)

- (void)asynchronousRequestFlickrFrob ;
- (void)asynchronousRequestFlickrToken ;

- (void)tellDelegateAuthenticationFailedWithError:(NSError *)error ;

- (void)requestToFlickrStarted:(ASIHTTPRequest *)request ;
- (void)requestToFlickrFinished:(ASIHTTPRequest *)request ;
- (void)requestToFlickrFailed:(ASIHTTPRequest *)request ;

- (void)postToFlickrStarted:(ASIFormDataRequest *)post ;
- (void)postToFlickrFinished:(ASIFormDataRequest *)post ;
- (void)postToFlickrFailed:(ASIFormDataRequest *)post ;

@end









@implementation DDFlickrClient

@synthesize frob ;


- (id)initWithDelegate:(id <DDFlickrClientDelegate>)theDelegate
{
	if (self = [super initWithDelegate: theDelegate])
	{
		[self setDelegate: theDelegate] ;
	}
	
	return self ;
}



- (DDSocialNetworkClientType)clientType
{
	return kDDSocialNetworkClientTypeFlickr ;
}



+ (NSString *)clientServiceKey
{
	return FLICKR_SERVICE_KEY ;
}



+ (NSString *)clientDomain
{
	return FLICKR_DOMAIN ;
}


- (NSString *)name
{
	return @"Flickr" ;
}





#pragma mark -
#pragma mark Authentication related methods

- (NSString *)authenticationURLString
{
	if (self.frob)
	{
		NSString *sigString = [NSString stringWithFormat: @"%@api_key%@frob%@permswrite", FLICKR_API_SECRET, FLICKR_API_KEY, self.frob] ;
		NSString *api_sig = [NSString MD5Hash: sigString] ;
		
		return [NSString stringWithFormat: @"http://api.flickr.com/services/auth/?api_key=%@&perms=write&frob=%@&api_sig=%@", FLICKR_API_KEY, frob, api_sig] ;
	}
	
	return nil ;
}



- (void)startLoginProcess
{
	[self asynchronousRequestFlickrFrob] ;
}



- (void)asynchronousRequestFlickrFrob
{
	NSString *sigString = [NSString stringWithFormat: @"%@api_key%@formatjsonmethodflickr.auth.getFrobnojsoncallback1", FLICKR_API_SECRET, FLICKR_API_KEY] ;
	NSString *api_sig = [NSString MD5Hash: sigString] ;
	
	NSString *URL = [NSString stringWithFormat: @"http://api.flickr.com/services/rest/?method=flickr.auth.getFrob&format=json&nojsoncallback=1&api_key=%@&api_sig=%@", FLICKR_API_KEY, api_sig] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URL]] ;
	[request setRequestMethod: @"GET"] ;
	[request setDidStartSelector: @selector(requestToFlickrStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFlickrFinished:)] ;
	[request setDidFailSelector: @selector(requestToFlickrFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFlickrRequestTypeFrob] forKey: flickrRequestType]] ;
	[request startAsynchronous] ;
}



- (NSDictionary *)pleaseParseThisURLResponseForMe:(NSString *)response
{
	if ([response isEqualToString: @"http://m.flickr.com/#/services/auth/"])
	{
		// we can now make a new request for the final token
		[self asynchronousRequestFlickrToken] ;
		// and we can close the dialog
		[loginDialog dismissModalViewControllerAnimated: YES] ;
	}
	return nil ;
}



- (void)asynchronousRequestFlickrToken
{
	NSString *sigString = [NSString stringWithFormat: @"%@api_key%@formatjsonfrob%@methodflickr.auth.getTokennojsoncallback1", FLICKR_API_SECRET, FLICKR_API_KEY, self.frob] ;
	NSString *api_sig = [NSString MD5Hash: sigString] ;
	
	// We create the URL for the token request, generate the request and the connection
	NSString *URL = [NSString stringWithFormat: @"http://api.flickr.com/services/rest/?method=flickr.auth.getToken&format=json&nojsoncallback=1&api_key=%@&api_sig=%@&frob=%@", FLICKR_API_KEY, api_sig, self.frob] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URL]] ;
	[request setRequestMethod: @"GET"] ;
	[request setDidStartSelector: @selector(requestToFlickrStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFlickrFinished:)] ;
	[request setDidFailSelector: @selector(requestToFlickrFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFlickrRequestTypeToken] forKey: flickrRequestType]] ;
	[request startAsynchronous] ;
}














#pragma mark -
#pragma mark Posting methods

- (void)getUserInfo
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSString *URL = [NSString stringWithFormat: @"http://api.flickr.com/services/rest/?method=flickr.people.getInfo&api_key=%@&user_id=%@&format=json&nojsoncallback=1", FLICKR_API_KEY, token.userID] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URL]] ;
	[request setRequestMethod: @"GET"] ;
	[request setDidStartSelector: @selector(requestToFlickrStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFlickrFinished:)] ;
	[request setDidFailSelector: @selector(requestToFlickrFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFlickrRequestTypeUserInfo] forKey: flickrRequestType]] ;
	[request startAsynchronous] ;
}



- (void)postImageToFlickr:(UIImage *)image withTitle:(NSString *)title andDescription:(NSString *)description
{
	// if no image, we can finish
	if (!image)
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to post an image"] ;
		if (delegate && [delegate respondsToSelector: @selector(flickrPostFailedWithError:)])
			[delegate performSelectorOnMainThread: @selector(flickrPostFailedWithError:) withObject: error waitUntilDone: NO] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSURL *URL = [NSURL URLWithString: @"http://api.flickr.com/services/upload/"] ;
	
	ASIFormDataRequest *post = [ASIFormDataRequest requestWithURL: URL] ;
	[post setRequestMethod: @"POST"] ;
	[post addPostValue: FLICKR_API_KEY forKey: @"api_key"] ;
	[post addPostValue: token.key forKey: @"auth_token"] ;
	
	NSString *sigString = [NSString stringWithFormat: @"%@api_key%@auth_token%@", FLICKR_API_SECRET, FLICKR_API_KEY, token.key] ;
	
	if (description && [description length])
	{
		[post addPostValue: description forKey: @"description"] ;
		sigString = [sigString stringByAppendingFormat: @"description%@", description] ;
	}
	
	/*
	 Apparently Flickr does not care about that and gives responses in XML...
	 
	 [post addPostValue: @"json" forKey: @"format"] ;
	 sigString = [sigString stringByAppendingString: @"formatjson"] ;
	 [post addPostValue: @"1" forKey: @"nojsoncallback"] ;
	 sigString = [sigString stringByAppendingString: @"nojsoncallback1"] ;
	 */
	
	if (title && [title length])
	{
		[post addPostValue: title forKey: @"title"] ;
		sigString = [sigString stringByAppendingFormat: @"title%@", title] ;
	}
	
	NSString *APISig = [NSString MD5Hash: sigString] ;
	[post addPostValue: APISig forKey: @"api_sig"] ;
	[post addData: UIImagePNGRepresentation(image) forKey: @"photo"] ;
	[post setDidStartSelector: @selector(postToFlickrStarted:)] ;
	[post setDidFinishSelector: @selector(postToFlickrFinished:)] ;
	[post setDidFailSelector: @selector(postToFlickrFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFlickrPostTypeImage] forKey: flickrPostType]] ;
	[post startAsynchronous] ;
}



- (void)getListOfGalleries
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSString *URL = [NSString stringWithFormat: @"http://api.flickr.com/services/rest/?method=flickr.galleries.getList&api_key=%@&user_id=%@&format=json&nojsoncallback=1", FLICKR_API_KEY, token.userID] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URL]] ;
	[request setRequestMethod: @"GET"] ;
	[request setDidStartSelector: @selector(requestToFlickrStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFlickrFinished:)] ;
	[request setDidFailSelector: @selector(requestToFlickrFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFlickrRequestTypeGalleryList] forKey: flickrRequestType]] ;
	[request startAsynchronous] ;
}



- (void)createGallery:(NSString *)galleryName withDescription:(NSString *)description
{
	// both name and description are required
	if (!galleryName || ![galleryName length] || !description || ![description length])
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to specify a name and a description for the gallery"] ;
		if (delegate && [delegate respondsToSelector: @selector(flickrPostFailedWithError:)])
			[delegate performSelectorOnMainThread: @selector(flickrPostFailedWithError:) withObject: error waitUntilDone: NO] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSURL *URL = [NSURL URLWithString: @"http://api.flickr.com/services/rest/"] ;
	
	ASIFormDataRequest *post = [ASIFormDataRequest requestWithURL: URL] ;
	[post setRequestMethod: @"POST"] ;
	[post addPostValue: @"flickr.galleries.create" forKey: @"method"] ;
	[post addPostValue: FLICKR_API_KEY forKey: @"api_key"] ;
	[post addPostValue: token.key forKey: @"auth_token"] ;
	[post addPostValue: galleryName forKey: @"title"] ;
	[post addPostValue: description forKey: @"description"] ;
	[post addPostValue: @"json" forKey: @"format"] ;
	[post addPostValue: @"1" forKey: @"nojsoncallback"] ;
	
	NSString *sigString = [NSString stringWithFormat: @"%@api_key%@auth_token%@description%@formatjsonmethodflickr.galleries.createnojsoncallback1title%@", FLICKR_API_SECRET, FLICKR_API_KEY, token.key, description, galleryName] ;
	NSString *APISig = [NSString MD5Hash: sigString] ;
	[post addPostValue: APISig forKey: @"api_sig"] ;
	
	[post setDidStartSelector: @selector(postToFlickrStarted:)] ;
	[post setDidFinishSelector: @selector(postToFlickrFinished:)] ;
	[post setDidFailSelector: @selector(postToFlickrFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFlickrPostTypeCreateGallery] forKey: flickrPostType]] ;
	[post startAsynchronous] ;
}



- (void)postImage:(NSString *)imageID toGallery:(NSString *)galleryID withComment:(NSString *)comment
{
	// both the gallery ID and the photo ID are required
	if (!imageID || ![imageID length] || !galleryID || ![galleryID length])
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to specify a gallery ID and a photo ID"] ;
		if (delegate && [delegate respondsToSelector: @selector(flickrPostFailedWithError:)])
			[delegate performSelectorOnMainThread: @selector(flickrPostFailedWithError:) withObject: error waitUntilDone: NO] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSURL *URL = [NSURL URLWithString: @"http://api.flickr.com/services/rest/"] ;
	
	ASIFormDataRequest *post = [ASIFormDataRequest requestWithURL: URL] ;
	[post setRequestMethod: @"POST"] ;
	[post addPostValue: @"flickr.galleries.addPhoto" forKey: @"method"] ;
	[post addPostValue: FLICKR_API_KEY forKey: @"api_key"] ;
	[post addPostValue: token.key forKey: @"auth_token"] ;
	[post addPostValue: imageID forKey: @"photo_id"] ;
	[post addPostValue: galleryID forKey: @"gallery_id"] ;
	
	NSString *sigString = [NSString stringWithFormat: @"%@api_key%@auth_token%@", FLICKR_API_SECRET, FLICKR_API_KEY, token.key] ;
	
	if (comment && [comment length])
	{
		[post addPostValue: comment forKey: @"comment"] ;
		sigString = [sigString stringByAppendingFormat: @"comment%@", comment] ;
	}
	
	[post addPostValue: @"json" forKey: @"format"] ;
	[post addPostValue: @"1" forKey: @"nojsoncallback"] ;
	
	sigString = [sigString stringByAppendingFormat: @"formatjsongallery_id%@methodflickr.galleries.addPhotonojsoncallback1photo_id%@", galleryID, imageID] ;
	NSString *APISig = [NSString MD5Hash: sigString] ;
	[post addPostValue: APISig forKey: @"api_sig"] ;
	
	[post setDidStartSelector: @selector(postToFlickrStarted:)] ;
	[post setDidFinishSelector: @selector(postToFlickrFinished:)] ;
	[post setDidFailSelector: @selector(postToFlickrFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFlickrPostTypeImageGallery] forKey: flickrPostType]] ;
	[post startAsynchronous] ;
}



- (void)getListOfPhotosets
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSString *URL = [NSString stringWithFormat: @"http://api.flickr.com/services/rest/?method=flickr.photosets.getList&api_key=%@&user_id=%@&format=json&nojsoncallback=1", FLICKR_API_KEY, token.userID] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URL]] ;
	[request setRequestMethod: @"GET"] ;
	[request setDidStartSelector: @selector(requestToFlickrStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFlickrFinished:)] ;
	[request setDidFailSelector: @selector(requestToFlickrFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFlickrRequestTypePhotoSetList] forKey: flickrRequestType]] ;
	[request startAsynchronous] ;
}



- (void)createPhotoset:(NSString *)photosetName withDescription:(NSString *)description withPrimaryPhoto:(NSString *)photoID ;
{
	// name, description and primary photo ID are required
	if (!photosetName || ![photosetName length] || !description || ![description length] || !photoID || ![photoID length])
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to specify a name, a description and a primary photo ID for the photoset"] ;
		if (delegate && [delegate respondsToSelector: @selector(flickrPostFailedWithError:)])
			[delegate performSelectorOnMainThread: @selector(flickrPostFailedWithError:) withObject: error waitUntilDone: NO] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSURL *URL = [NSURL URLWithString: @"http://api.flickr.com/services/rest/"] ;
	
	ASIFormDataRequest *post = [ASIFormDataRequest requestWithURL: URL] ;
	[post setRequestMethod: @"POST"] ;
	[post addPostValue: @"flickr.photosets.create" forKey: @"method"] ;
	[post addPostValue: FLICKR_API_KEY forKey: @"api_key"] ;
	[post addPostValue: token.key forKey: @"auth_token"] ;
	[post addPostValue: photosetName forKey: @"title"] ;
	[post addPostValue: description forKey: @"description"] ;
	[post addPostValue: photoID forKey: @"primary_photo_id"] ;
	[post addPostValue: @"json" forKey: @"format"] ;
	[post addPostValue: @"1" forKey: @"nojsoncallback"] ;
	
	NSString *sigString = [NSString stringWithFormat: @"%@api_key%@auth_token%@description%@formatjsonmethodflickr.photosets.createnojsoncallback1primary_photo_id%@title%@", FLICKR_API_SECRET, FLICKR_API_KEY, token.key, description, photoID, photosetName] ;
	NSString *APISig = [NSString MD5Hash: sigString] ;
	[post addPostValue: APISig forKey: @"api_sig"] ;
	
	[post setDidStartSelector: @selector(postToFlickrStarted:)] ;
	[post setDidFinishSelector: @selector(postToFlickrFinished:)] ;
	[post setDidFailSelector: @selector(postToFlickrFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFlickrPostTypeCreatePhotoSet] forKey: flickrPostType]] ;
	[post startAsynchronous] ;
}



- (void)postImage:(NSString *)imageID toPhotoset:(NSString *)photosetID
{
	// both the photoset ID and the photo ID are required
	if (!imageID || ![imageID length] || !photosetID || ![photosetID length])
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"You need to specify a photoset ID and a photo ID"] ;
		if (delegate && [delegate respondsToSelector: @selector(flickrPostFailedWithError:)])
			[delegate performSelectorOnMainThread: @selector(flickrPostFailedWithError:) withObject: error waitUntilDone: NO] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self startLoginProcess] ;
		return ;
	}
	
	NSURL *URL = [NSURL URLWithString: @"http://api.flickr.com/services/rest/"] ;
	
	ASIFormDataRequest *post = [ASIFormDataRequest requestWithURL: URL] ;
	[post setRequestMethod: @"POST"] ;
	[post addPostValue: @"flickr.photosets.addPhoto" forKey: @"method"] ;
	[post addPostValue: FLICKR_API_KEY forKey: @"api_key"] ;
	[post addPostValue: token.key forKey: @"auth_token"] ;
	[post addPostValue: imageID forKey: @"photo_id"] ;
	[post addPostValue: photosetID forKey: @"photoset_id"] ;
	[post addPostValue: @"json" forKey: @"format"] ;
	[post addPostValue: @"1" forKey: @"nojsoncallback"] ;
	
	NSString *sigString = [NSString stringWithFormat: @"%@api_key%@auth_token%@formatjsonmethodflickr.photosets.addPhotonojsoncallback1photo_id%@photoset_id%@", FLICKR_API_SECRET, FLICKR_API_KEY, token.key, imageID, photosetID] ;
	NSString *APISig = [NSString MD5Hash: sigString] ;
	[post addPostValue: APISig forKey: @"api_sig"] ;
	
	[post setDidStartSelector: @selector(postToFlickrStarted:)] ;
	[post setDidFinishSelector: @selector(postToFlickrFinished:)] ;
	[post setDidFailSelector: @selector(postToFlickrFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFlickrPostTypeImagePhotoSet] forKey: flickrPostType]] ;
	[post startAsynchronous] ;
}

















#pragma mark -
#pragma mark Private helper methods

/*
 NOTE: we need this method because we have to perform a selector
 with more than one object (argument) on the main thread...
 */

- (void)tellDelegateAuthenticationFailedWithError:(NSError *)error
{
	if (![NSThread isMainThread])
	{
		[self performSelectorOnMainThread: @selector(tellDelegateAuthenticationFailedWithError:) withObject: error waitUntilDone: YES] ;
		return ;
	}
	
	// this should have already been checked, but better being too prudent...
	if ([delegate respondsToSelector: @selector(socialMediaClient:authenticationDidFailWithError:)])
		[delegate socialMediaClient: self authenticationDidFailWithError: error] ;
}











#pragma mark -
#pragma mark Connection and parsing methods

- (void)requestToFlickrStarted:(ASIHTTPRequest *)request
{
	NSLog(@"started") ;
}



- (void)requestToFlickrFinished:(ASIHTTPRequest *)request
{
	NSLog(@"finished") ;
	DDFlickrRequestType requestType = [[request.userInfo objectForKey: flickrRequestType] intValue] ;
	
	if (requestType == DDFlickrRequestTypeFrob)
	{
		if ([request error])
		{
			// we send a shout to the delegate that the authentication failed
			NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The authentication failed"] ;
			if (delegate && [delegate respondsToSelector: @selector(socialMediaClient:authenticationDidFailWithError:)])
				[self tellDelegateAuthenticationFailedWithError: error] ;
			
			return ;
		}
		
		NSString *responseString = [request responseString] ;
		NSMutableDictionary *responseJSON = [responseString JSONValue] ;
		
		// we can now get the Frob
		NSString *theFrob = nil ;
		if (responseJSON)
		{
			NSDictionary *frobDic = [responseJSON objectForKey: @"frob"] ;
			if (frobDic)
				theFrob = [frobDic objectForKey: @"_content"] ;
		}
		
		if (theFrob)
		{
			self.frob = theFrob ;
			[self showLoginDialog] ;
		}
		else
		{
			// we send a shout to the delegate that the authentication failed
			NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The authentication failed"] ;
			if (delegate && [delegate respondsToSelector: @selector(socialMediaClient:authenticationDidFailWithError:)])
				[self tellDelegateAuthenticationFailedWithError: error] ;
			
			return ;
		}
	}
	else if (requestType == DDFlickrRequestTypeToken)
	{
		if ([request error])
		{
			// we send a shout to the delegate that the authentication failed
			NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The authentication failed"] ;
			if (delegate && [delegate respondsToSelector: @selector(socialMediaClient:authenticationDidFailWithError:)])
				[self tellDelegateAuthenticationFailedWithError: error] ;
			
			return ;
		}
		
		NSString *responseString = [request responseString] ;
		NSMutableDictionary *responseJSON = [responseString JSONValue] ;
		
		// we can now get the fucking Token
		NSString *theToken = nil ;
		NSString *theUserID = nil ;
		if (responseJSON)
		{
			NSDictionary *authDic = [responseJSON objectForKey: @"auth"] ;
			if (authDic)
			{
				NSDictionary *tokenDic = [authDic objectForKey: @"token"] ;
				if (tokenDic)
				{
					theToken = [tokenDic objectForKey: @"_content"] ;
				}
				NSDictionary *userDic = [authDic objectForKey: @"user"] ;
				if (userDic)
				{
					theUserID = [userDic objectForKey: @"nsid"] ;
				}
			}
		}
		
		if (theToken)
		{
			// we can now store the token
			OAuthToken *newToken = [[[OAuthToken alloc] initWithService: [[self class] clientServiceKey] andKey: theToken andSecret: @"NoSecretForFlickr" andCreationDate: nil andDuration: nil andUserID: theUserID] autorelease] ;
			[self setToken: newToken] ;
			[self.token storeToUserDefaults] ;
			
			// we give a shout to the delegate
			if (delegate && [delegate respondsToSelector: @selector(socialMediaClientAuthenticationDidSucceed:)])
				[delegate performSelectorOnMainThread: @selector(socialMediaClientAuthenticationDidSucceed:) withObject: self waitUntilDone: NO] ;
		}
		else
		{
			// we send a shout to the delegate that the authentication failed
			NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The authentication failed"] ;
			if (delegate && [delegate respondsToSelector: @selector(socialMediaClient:authenticationDidFailWithError:)])
				[self tellDelegateAuthenticationFailedWithError: error] ;
		}
	}
	else
	{
		if ((requestType == DDFlickrRequestTypeUserInfo) || (requestType == DDFlickrRequestTypeGalleryList) || (requestType == DDFlickrRequestTypePhotoSetList))
		{
			NSString *responseString = [request responseString] ;
			NSMutableDictionary *responseJSON = [responseString JSONValue] ;
			
			if ([[responseJSON objectForKey: @"stat"] isEqualToString: @"ok"])
			{
				if (delegate && [delegate respondsToSelector: @selector(flickrRequest:didSucceedAndReturned:)])
					[delegate flickrRequest: requestType didSucceedAndReturned: responseJSON] ;
			}
			else
			{
				NSError *error = [DDSocialNetworkClient generateErrorWithMessage: [NSString stringWithFormat: @"The request failed"]] ;
				if (delegate && [delegate respondsToSelector: @selector(flickrRequest:failedWithError:)])
					[delegate flickrRequest: requestType failedWithError: error] ;
			}
		}
	}
}



- (void)requestToFlickrFailed:(ASIHTTPRequest *)request
{
	NSLog(@"failed") ;
	DDFlickrRequestType requestType = [[request.userInfo objectForKey: flickrRequestType] intValue] ;
	
	if ((requestType == DDFlickrRequestTypeFrob) || (requestType == DDFlickrRequestTypeToken))
	{
		// we send a shout to the delegate that the authentication failed
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: @"The authentication failed"] ;
		if (delegate && [delegate respondsToSelector: @selector(socialMediaClient:authenticationDidFailWithError:)])
			[self tellDelegateAuthenticationFailedWithError: error] ;
	}
	else
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: [NSString stringWithFormat: @"The request failed"]] ;
		if (delegate && [delegate respondsToSelector: @selector(flickrRequest:failedWithError:)])
			[delegate flickrRequest: requestType failedWithError: error] ;
	}
}



- (void)postToFlickrStarted:(ASIFormDataRequest *)post
{
	NSLog(@"post started") ;
}



- (void)postToFlickrFinished:(ASIFormDataRequest *)post
{
	NSLog(@"post finished") ;
	DDFlickrPostType postType = [[post.userInfo objectForKey: flickrPostType] intValue] ;
	
	NSString *postInfo = [post.userInfo objectForKey: @"whichPost"] ;
	NSString *responseString = [post responseString] ;
	NSMutableDictionary *responseJSON = [responseString JSONValue] ;
	
	if ([[responseJSON objectForKey: @"stat"] isEqualToString: @"ok"])
	{
		if (delegate && [delegate respondsToSelector: @selector(flickrPost:didSucceedAndReturned:)])
			[delegate flickrPost: postType didSucceedAndReturned: responseJSON] ;
	}
	else
	{
		NSError *error = [DDSocialNetworkClient generateErrorWithMessage: [NSString stringWithFormat: @"The post %@ failed", postInfo]] ;
		if (delegate && [delegate respondsToSelector: @selector(flickrPost:failedWithError:)])
			[delegate flickrPost: postType failedWithError: error] ;
	}
}



- (void)postToFlickrFailed:(ASIFormDataRequest *)post
{
	NSLog(@"post failed") ;
	DDFlickrPostType postType = [[post.userInfo objectForKey: flickrPostType] intValue] ;
	
	NSString *postInfo = [post.userInfo objectForKey: @"whichPost"] ;
	NSError *error = [DDSocialNetworkClient generateErrorWithMessage: [NSString stringWithFormat: @"The post %@ failed", postInfo]] ;
	if (delegate && [delegate respondsToSelector: @selector(flickrPost:failedWithError:)])
		[delegate flickrPost: postType failedWithError: error] ;
}


@end
