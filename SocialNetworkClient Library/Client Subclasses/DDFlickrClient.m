//
//  DDFlickrClient.m
//  SocialNetworkClient
//
//  Created by Damien DeVille on 8/9/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import "DDFlickrClient.h"
#import "NSString+MD5.h"
#import "JSON.h"
#import "ASIFormDataRequest.h"

#define flickrPostType		@"FlickrPostType"
#define flickrRequestType	@"FlickrRequestType"


@interface DDFlickrClient (Private)

- (void)asynchronousRequestFlickrFrob ;
- (void)asynchronousRequestFlickrToken ;

- (void)requestToFlickrStarted:(ASIHTTPRequest *)request ;
- (void)requestToFlickrFinished:(ASIHTTPRequest *)request ;
- (void)requestToFlickrFailed:(ASIHTTPRequest *)request ;

- (void)postToFlickrStarted:(ASIFormDataRequest *)post ;
- (void)postToFlickrFinished:(ASIFormDataRequest *)post ;
- (void)postToFlickrFailed:(ASIFormDataRequest *)post ;

@end


@implementation DDFlickrClient

- (id)initWithDelegate:(id <DDFlickrClientDelegate>)theDelegate
{
	if (self = [super initWithDelegate: theDelegate])
	{
		[self setDelegate: theDelegate] ;
	}
	
	return self ;
}

- (void)dealloc
{
	[super dealloc] ;
}

- (DDSocialClientType)clientType
{
	return kDDSocialClientFlickr ;
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
	if (frob)
	{
		NSString *sigString = [NSString stringWithFormat: @"%@api_key%@frob%@permswrite", FLICKR_API_SECRET, FLICKR_API_KEY, frob] ;
		NSString *api_sig = [sigString MD5Hash] ;
		
		return [NSString stringWithFormat: @"http://api.flickr.com/services/auth/?api_key=%@&perms=write&frob=%@&api_sig=%@", FLICKR_API_KEY, frob, api_sig] ;
	}
	
	return nil ;
}

- (void)login
{
	if ([FLICKR_API_KEY length] == 0 || [FLICKR_API_SECRET length] == 0)
	{
		NSLog(@"You need to specify FLICKR_API_KEY and FLICKR_API_SECRET in DDSocialClient.h") ;
		
		NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 7 userInfo: [NSDictionary dictionaryWithObject: @"Unspecified consumer key and consumer secret." forKey: NSLocalizedDescriptionKey]] ;
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
	
	[self asynchronousRequestFlickrFrob] ;
	[self showLoginDialog] ;
}

- (void)asynchronousRequestFlickrFrob
{
	NSString *sigString = [NSString stringWithFormat: @"%@api_key%@formatjsonmethodflickr.auth.getFrobnojsoncallback1", FLICKR_API_SECRET, FLICKR_API_KEY] ;
	NSString *api_sig = [sigString MD5Hash] ;
	
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
	NSString *sigString = [NSString stringWithFormat: @"%@api_key%@formatjsonfrob%@methodflickr.auth.getTokennojsoncallback1", FLICKR_API_SECRET, FLICKR_API_KEY, frob] ;
	NSString *api_sig = [sigString MD5Hash] ;
	
	// We create the URL for the token request, generate the request and the connection
	NSString *URL = [NSString stringWithFormat: @"http://api.flickr.com/services/rest/?method=flickr.auth.getToken&format=json&nojsoncallback=1&api_key=%@&api_sig=%@&frob=%@", FLICKR_API_KEY, api_sig, frob] ;
	
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URL]] ;
	[request setRequestMethod: @"GET"] ;
	[request setDidStartSelector: @selector(requestToFlickrStarted:)] ;
	[request setDidFinishSelector: @selector(requestToFlickrFinished:)] ;
	[request setDidFailSelector: @selector(requestToFlickrFailed:)] ;
	[request setDelegate: self] ;
	[request setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFlickrRequestTypeToken] forKey: flickrRequestType]] ;
	[request startAsynchronous] ;
	
	[frob release], frob = nil ;
}




#pragma mark -
#pragma mark Posting methods

- (void)getUserInfo
{
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
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
	if (image == nil)
	{
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to post an image" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(flickrPost:failedWithError:)])
			[delegate flickrPost: DDFlickrPostTypeImage failedWithError: error] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
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
	
	// Apparently Flickr does not care about that and gives responses in XML...
	 
//	[post addPostValue: @"json" forKey: @"format"] ;
//	sigString = [sigString stringByAppendingString: @"formatjson"] ;
//	[post addPostValue: @"1" forKey: @"nojsoncallback"] ;
//	sigString = [sigString stringByAppendingString: @"nojsoncallback1"] ;
	
	if (title && [title length])
	{
		[post addPostValue: title forKey: @"title"] ;
		sigString = [sigString stringByAppendingFormat: @"title%@", title] ;
	}
	
	NSString *APISig = [sigString MD5Hash] ;
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
		[self login] ;
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
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to specify a name and a description for the gallery" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(flickrPost:failedWithError:)])
			[delegate flickrPost: DDFlickrPostTypeCreateGallery failedWithError: error] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
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
	NSString *APISig = [sigString MD5Hash] ;
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
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to specify a gallery ID and a photo ID" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(flickrPost:failedWithError:)])
			[delegate flickrPost: DDFlickrPostTypeImageGallery failedWithError: error] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
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
	NSString *APISig = [sigString MD5Hash] ;
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
		[self login] ;
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
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to specify a name, a description and a primary photo ID for the photoset" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(flickrPost:failedWithError:)])
			[delegate flickrPost: DDFlickrPostTypeCreatePhotoSet failedWithError: error] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
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
	NSString *APISig = [sigString MD5Hash] ;
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
		NSError *error = [NSError errorWithDomain: DDSocialClientError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"Misconstruct post or request: You need to specify a photoset ID and a photo ID" forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(flickrPost:failedWithError:)])
			[delegate flickrPost: DDFlickrPostTypeImagePhotoSet failedWithError: error] ;
		return ;
	}
	
	// if no token, we show the login window and get the hell outta here
	if (![self serviceHasValidToken])
	{
		[self login] ;
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
	NSString *APISig = [sigString MD5Hash] ;
	[post addPostValue: APISig forKey: @"api_sig"] ;
	
	[post setDidStartSelector: @selector(postToFlickrStarted:)] ;
	[post setDidFinishSelector: @selector(postToFlickrFinished:)] ;
	[post setDidFailSelector: @selector(postToFlickrFailed:)] ;
	[post setDelegate: self] ;
	[post setUserInfo: [NSDictionary dictionaryWithObject: [NSNumber numberWithInt: DDFlickrPostTypeImagePhotoSet] forKey: flickrPostType]] ;
	[post startAsynchronous] ;
}



#pragma mark -
#pragma mark Connection and parsing methods

- (void)requestToFlickrStarted:(ASIHTTPRequest *)request
{
	
}

- (void)requestToFlickrFinished:(ASIHTTPRequest *)request
{
	DDFlickrRequestType requestType = [[request.userInfo objectForKey: flickrRequestType] intValue] ;
	
	if (requestType == DDFlickrRequestTypeFrob)
	{
		if ([request error])
		{
			// dismiss the login dialog
			[loginDialog dismissAnimated: YES] ;
			
			// we send a shout to the delegate that the authentication failed
			NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 5 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the initial token failed." forKey: NSLocalizedDescriptionKey]] ;
			if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
				[delegate socialClient: self authenticationDidFailWithError: error] ;
			
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
			frob = [theFrob retain] ;
			[self showLoginDialog] ;
		}
		else
		{
			// dismiss the login dialog
			[loginDialog dismissAnimated: YES] ;
			
			// we send a shout to the delegate that the authentication failed
			NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 5 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the initial token failed." forKey: NSLocalizedDescriptionKey]] ;
			if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
				[delegate socialClient: self authenticationDidFailWithError: error] ;
			
			return ;
		}
	}
	else if (requestType == DDFlickrRequestTypeToken)
	{
		if ([request error])
		{
			// dismiss the login dialog
			[loginDialog dismissAnimated: YES] ;
			
			// we send a shout to the delegate that the authentication failed
			NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 6 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the OAuth token failed." forKey: NSLocalizedDescriptionKey]] ;
			if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
				[delegate socialClient: self authenticationDidFailWithError: error] ;
			
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
			[self.token store] ;
			
			// we give a shout to the delegate
			if (delegate && [delegate respondsToSelector: @selector(socialClientAuthenticationDidSucceed:)])
				[delegate performSelectorOnMainThread: @selector(socialClientAuthenticationDidSucceed:) withObject: self waitUntilDone: NO] ;
			// and close the login dialog
			[loginDialog dismissAnimated: YES] ;
		}
		else
		{
			// dismiss the login dialog
			[loginDialog dismissAnimated: YES] ;
			
			// we send a shout to the delegate that the authentication failed
			NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 6 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the OAuth token failed." forKey: NSLocalizedDescriptionKey]] ;
			if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
				[delegate socialClient: self authenticationDidFailWithError: error] ;
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
				NSError *error = [NSError errorWithDomain: DDSocialClientError code: 4 userInfo: [NSDictionary dictionaryWithObject: @"The request failed." forKey: NSLocalizedDescriptionKey]] ;
				if (delegate && [delegate respondsToSelector: @selector(flickrRequest:failedWithError:)])
					[delegate flickrRequest: requestType failedWithError: error] ;
			}
		}
	}
}

- (void)requestToFlickrFailed:(ASIHTTPRequest *)request
{
	DDFlickrRequestType requestType = [[request.userInfo objectForKey: flickrRequestType] intValue] ;
	
	if ((requestType == DDFlickrRequestTypeFrob) || (requestType == DDFlickrRequestTypeToken))
	{
		// dismiss the login dialog
		[loginDialog dismissAnimated: YES] ;
		
		// we send a shout to the delegate that the authentication failed
		NSError *error ;
		if ([[request.error domain] isEqualToString: @"ASIHTTPRequestErrorDomain"] && [request.error code] == 2)
			error = [NSError errorWithDomain: DDAuthenticationError code: 2 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request timed out." forKey: NSLocalizedDescriptionKey]] ;
		else if (requestType == DDFlickrRequestTypeFrob)
			error = [NSError errorWithDomain: DDAuthenticationError code: 5 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the initial token failed." forKey: NSLocalizedDescriptionKey]] ;
		else if (requestType == DDFlickrRequestTypeToken)
			error = [NSError errorWithDomain: DDAuthenticationError code: 6 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the OAuth token failed." forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
			[delegate socialClient: self authenticationDidFailWithError: error] ;
	}
	else
	{
		NSError *error ;
		if ([[request.error domain] isEqualToString: @"ASIHTTPRequestErrorDomain"] && [request.error code] == 2)
			error = [NSError errorWithDomain: DDSocialClientError code: 2 userInfo: [NSDictionary dictionaryWithObject: @"The request timed out." forKey: NSLocalizedDescriptionKey]] ;
		else
			error = [NSError errorWithDomain: DDSocialClientError code: 0 userInfo: [NSDictionary dictionaryWithObject: @"Unknown error." forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(flickrRequest:failedWithError:)])
			[delegate flickrRequest: requestType failedWithError: error] ;
	}
}

- (void)postToFlickrStarted:(ASIFormDataRequest *)post
{
	
}

- (void)postToFlickrFinished:(ASIFormDataRequest *)post
{
	DDFlickrPostType postType = [[post.userInfo objectForKey: flickrPostType] intValue] ;
	
	NSString *responseString = [post responseString] ;
	
	if (postType == DDFlickrPostTypeImage)
	{
		// the response here is in XML...
		
		// for now assume that it means the post was successful (bad assumption, will have to change!)
		if (delegate && [delegate respondsToSelector: @selector(flickrPost:didSucceedAndReturned:)])
			[delegate flickrPost: postType didSucceedAndReturned: nil] ;
	}
	else
	{
		NSMutableDictionary *responseJSON = [responseString JSONValue] ;
		
		if ([[responseJSON objectForKey: @"stat"] isEqualToString: @"ok"])
		{
			if (delegate && [delegate respondsToSelector: @selector(flickrPost:didSucceedAndReturned:)])
				[delegate flickrPost: postType didSucceedAndReturned: responseJSON] ;
		}
		else
		{
			NSError *error = [NSError errorWithDomain: DDSocialClientError code: 4 userInfo: [NSDictionary dictionaryWithObject: @"The post failed." forKey: NSLocalizedDescriptionKey]] ;
			if (delegate && [delegate respondsToSelector: @selector(flickrPost:failedWithError:)])
				[delegate flickrPost: postType failedWithError: error] ;
		}
	}
}

- (void)postToFlickrFailed:(ASIFormDataRequest *)post
{
	DDFlickrPostType postType = [[post.userInfo objectForKey: flickrPostType] intValue] ;
	
	NSError *error ;
	if ([[post.error domain] isEqualToString: @"ASIHTTPRequestErrorDomain"] && [post.error code] == 2)
		error = [NSError errorWithDomain: DDSocialClientError code: 2 userInfo: [NSDictionary dictionaryWithObject: @"The request timed out." forKey: NSLocalizedDescriptionKey]] ;
	else
		error = [NSError errorWithDomain: DDSocialClientError code: 0 userInfo: [NSDictionary dictionaryWithObject: @"Unknown error." forKey: NSLocalizedDescriptionKey]] ;
	if (delegate && [delegate respondsToSelector: @selector(flickrPost:failedWithError:)])
		[delegate flickrPost: postType failedWithError: error] ;
}


@end
