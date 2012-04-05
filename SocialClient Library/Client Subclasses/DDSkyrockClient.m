//
//  DDSkyrockClient.m
//  DDSocialTest
//
//  Created by Pascal Costa-Cunha on 09/01/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "DDSkyrockClient.h"

#import "OAuthSign.h"
#import "JSON.h"

#import "ASIFormDataRequest.h"


#define kSPCBaseURL @"https://api.skyrock.mobi/v2/"
#define SPC_FakeCallBackURL @"http://monsite.fr/"


#ifdef DEBUG
#	define SkyLog(fmt, ...) NSLog((@"%s:%d " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
#else
#	define SkyLog(...)
#endif


@interface DDSkyrockClient ()

- (void)asynchronousRequestInitialToken;

@property (nonatomic, retain) NSString *p_initialToken;
@property (nonatomic, retain) NSString *p_secretToken;

@property (nonatomic, retain) id p_argRestart;
@property (nonatomic, assign) NSInteger p_typeRestart;

-(void) _postBlogPhoto:(NSArray*)args;
-(void) _postBlogArticle:(NSArray*)args;


- (void)requestOAuthStarted:(ASIHTTPRequest *)request;
- (void)requestOAuthFinished:(ASIHTTPRequest *)request;
- (void)requestOAuthFailed:(ASIHTTPRequest *)request;

- (void)requestAPIStarted:(ASIHTTPRequest *)request;
- (void)requestAPIFinished:(ASIHTTPRequest *)request;
- (void)requestAPIFailed:(ASIHTTPRequest *)request;

-(ASIFormDataRequest*) _getBlogRequestFor:(NSDictionary*)infos;

@end




@implementation DDSkyrockClient

@synthesize p_initialToken, p_secretToken;
@synthesize p_argRestart, p_typeRestart;


@dynamic delegate ;

- (id)initWithDelegate:(id <DDSkyrockClientDelegate>)theDelegate
{
	if ((self = [super initWithDelegate: theDelegate]))
	{
		[self setDelegate: theDelegate] ;
	}
	
	return self ;
}


- (DDSocialClientType)clientType
{
	return kDDSocialClientUnknown;
}

+ (NSString *)clientServiceKey
{
	return @"Skyrock.com";
}

+ (NSString *)clientDomain
{
	return @"skyrock.mobi" ;
}

- (NSString *)name
{
	return @"Skyrock.com";
}


#pragma mark - Helper Request Type


#define SPC_RequestType @"skyrockRequestType"

#define SPC_RequestTypeInitialToken 1
#define SPC_RequestTypeValidationToken 2


#define SPC_RequestTypeToRestart 9

#define SPC_RequestTypeBlogPhoto 10
#define SPC_RequestTypeBlogArticle 11
#define SPC_RequestTypeProfilePhoto 12
#define SPC_RequestTypeUpdateStatus 13
#define SPC_RequestTypeGetUser 14



-(void) _setRequestType:(NSInteger)type toRequest:(ASIHTTPRequest*)request
{
    [request setUserInfo:[NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:type] forKey:SPC_RequestType]];
}

-(NSInteger) _retreiveRequestTypeForRequest:(ASIHTTPRequest*)request
{
	return [[request.userInfo objectForKey:SPC_RequestType] integerValue];    
}





#pragma mark - OAuth authentication related methods

+ (BOOL)serviceHasValidToken
{
	if ([OAuthToken tokenForService: [[self class] clientServiceKey]])
		return YES ;
	return NO ;
}

- (BOOL)serviceHasValidToken
{
	// Watch, the token is also assigned here!
	if ((self.token = [OAuthToken tokenForService: [[self class] clientServiceKey]]))
		return YES ;
	return NO ;
}

+ (void)logout
{
	[OAuthToken deleteTokenForService: [self clientServiceKey]] ;
	
	// we remove the cookies for the current service
	NSString *serviceCookieDomain = [self clientDomain] ;
	
	for (NSHTTPCookie* cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies])
	{
		NSRange textRange = [[cookie.domain lowercaseString] rangeOfString:[serviceCookieDomain lowercaseString]] ;
		// we have to make sure none of these is nil
		if (cookie.domain && serviceCookieDomain)
		{
			if(textRange.location != NSNotFound)
				[[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie: cookie] ;
		}
	}
}



/*
 Each subclass HAS TO implement this method in order
 to return the correct URL string for performing the authentication
 */
- (NSString *)authenticationURLString
{
    
	if (self.p_initialToken)
	{
		NSString *URLFormat = kSPCBaseURL@"oauth/authenticate?oauth_token=%@" ;        
		return [NSString stringWithFormat: URLFormat, self.p_initialToken] ;
	}
    
	return nil ;    
}


- (void)login
{
	if ([SKYROCK_CONSUMER_KEY length] == 0 || [SKYROCK_CONSUMER_SECRET length] == 0)
	{
		SkyLog(@"You need to specify SKYROCK_CONSUMER_KEY and SKYROCK_CONSUMER_SECRET in DDSocialClient.h") ;
		
		NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 7 userInfo: [NSDictionary dictionaryWithObject: @"Unspecified consumer key and consumer secret." forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
			[delegate socialClient: self authenticationDidFailWithError: error] ;
		return ;
	}
	
	if ([[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == NotReachable)
	{
		NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 1 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because because there is no Internet connection." forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
			[delegate socialClient: self authenticationDidFailWithError: error] ;
		return ;
	}
	
	[self asynchronousRequestInitialToken] ;
	//[self showLoginDialog] ;
}

- (void)asynchronousRequestInitialToken
{
	NSString *URL = kSPCBaseURL@"oauth/initiate" ;
	
	// Create the authorization header
    NSString *oauth_header = [OAuthSign generateOAuthAuthorizationHeaderForMethod:@"GET" 
                                                                              URL:URL 
                                                                         callback:SPC_FakeCallBackURL 
                                                                      consumerKey:SKYROCK_CONSUMER_KEY 
                                                                consumerKeySecret:SKYROCK_CONSUMER_SECRET 
                                                                            token:nil 
                                                                      tokenSecret:nil 
                                                                         verifier:nil 
                                                                   postParameters:nil];
    
    
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URL]] ;
	[request setRequestMethod: @"GET"] ;
	[request addRequestHeader: @"Authorization" value: oauth_header] ;
	[request setDidStartSelector: @selector(requestOAuthStarted:)] ;
	[request setDidFinishSelector: @selector(requestOAuthFinished:)] ;
	[request setDidFailSelector: @selector(requestOAuthFailed:)] ;
	[request setDelegate: self] ;
    [self _setRequestType:SPC_RequestTypeInitialToken toRequest:request];
    
	[request startAsynchronous] ;
}


- (void)showLoginDialog
{
	/*
     NOTE: since we deal a lot with asynchronous request, we never really know
     where we come from so to be safe, we switch to the main thread
	 */
    
	if ([NSThread currentThread] != [NSThread mainThread])
	{
		[self performSelectorOnMainThread: @selector(showLoginDialog) withObject: nil waitUntilDone: YES] ;
		return ;
	}
	
	if (loginDialog)
	{
		// update the login dialog by loading a new URL request
		NSURL *URL = [NSURL URLWithString: [self authenticationURLString]] ;
		[loginDialog setRequestURL: URL] ;
		return ;
	}
	
    /*
     // check whether the delegate blocks the login dialog, display an authentication error in that case
     if (delegate && [delegate respondsToSelector: @selector(shouldDisplayLoginForSocialClient:)])
     {
     if ([delegate shouldDisplayLoginForSocialClient: self] == NO)
     {
     NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 3 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the login dialog could not be displayed." forKey: NSLocalizedDescriptionKey]] ;
     if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
     [delegate socialClient: self authenticationDidFailWithError: error] ;
     return ;
     }
     }
     */
    
    
	// no block from the delegate, show the login dialog
	NSURL *URL = [NSURL URLWithString: [self authenticationURLString]] ;
	loginDialog = [[DDSocialClientLogin alloc] initWithURL: URL delegate: self] ;
	
	[loginDialog presentAnimated: YES] ;
}


-(NSString*) oauthHeaderForUrl:(NSString*)url isPost:(BOOL)post postParams:(NSDictionary*)postParams
{
    if ([self serviceHasValidToken]) {
        
        
        if ([self.token isValid] && ![self.token hasExpired]) {
            OAuthToken* tok = self.token;    
            
            return  [OAuthSign generateOAuthAuthorizationHeaderForMethod:(post)?@"POST":@"GET" 
                                                                     URL:url
                                                                callback:nil
                                                             consumerKey:SKYROCK_CONSUMER_KEY 
                                                       consumerKeySecret:SKYROCK_CONSUMER_SECRET 
                                                                   token:tok.key
                                                             tokenSecret:tok.secret
                                                                verifier:nil
                                                          postParameters:nil/*postParams*/];  //postParams is not used with json post data
        }
    }
    
    return nil;
}



#pragma mark - DDSocialNetworkClientLoginDialog delegate methods

- (void)oAuthTokenFound:(OAuthToken *)accessToken
{
	// we first set the service in the token in case this has not been done earlier
	[accessToken setService: [[self class] clientServiceKey]] ;
	
	// and we store it
	[self setToken: accessToken] ;
	[accessToken store] ;
	
	// we can tell the delegate the authentication worked
	if(delegate && [delegate respondsToSelector: @selector(socialClientAuthenticationDidSucceed:)])
		[delegate socialClientAuthenticationDidSucceed: self] ;
	
	// and we can close the dialog now
	[loginDialog dismissAnimated: YES] ;
}

- (void)closeTapped:(DDSocialClientLogin *)loginVC
{
	// we dismiss the view controller here
	[loginDialog dismissAnimated: YES] ;
	
	/*
     In function of the value of the token here, we can deduce
     if the login worked or not.
	 */
	
	if ([self serviceHasValidToken])
	{
		if(delegate && [delegate respondsToSelector: @selector(socialClientAuthenticationDidSucceed:)])
			[delegate socialClientAuthenticationDidSucceed: self] ;
	}
	else
	{
		NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 4 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the user closed the login dialog." forKey: NSLocalizedDescriptionKey]] ;
		if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
			[delegate socialClient: self authenticationDidFailWithError: error] ;
	}
}

- (void)socialClientLoginDidDismiss:(DDSocialClientLogin *)loginVC
{
	[loginDialog release] ;
	loginDialog = nil ;
	
	// tell the delegate about it
	if (delegate && [delegate respondsToSelector: @selector(didDismissLoginForSocialClient:)])
		[delegate didDismissLoginForSocialClient: self] ;
}

- (NSString *)serviceName
{
	return [[self class] clientServiceKey] ;
}


- (NSDictionary *)parseURL:(NSString *)response
//- (NSDictionary *)pleaseParseThisURLResponseForMe:(NSString *)response
{
    
    NSString* toTrack = SPC_FakeCallBackURL;
    const NSUInteger LENGTH = [toTrack length];
    
	if ([response length] > LENGTH)
	{                                                         
		if ([[response substringToIndex:LENGTH] isEqualToString:toTrack])
		{
			// we have got what we are looking for, start parsing it
			NSMutableDictionary *responseDictionary = [[NSMutableDictionary alloc] initWithCapacity: 2]  ;
			
			NSRange oauthTokenRange = [response rangeOfString: @"oauth_token="] ;
			if (oauthTokenRange.length > 0)
			{
				NSString *oauthToken ;
				int fromIndex = oauthTokenRange.location + oauthTokenRange.length ;
				oauthToken = [response substringFromIndex: fromIndex] ;
				oauthToken = [oauthToken stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ;
				NSRange periodRange = [oauthToken rangeOfString: @"&"] ;
                if (periodRange.location!=NSNotFound)                
                    oauthToken = [oauthToken substringToIndex: periodRange.location] ;
				
				// we print the token and build a dictionary that we return
				[responseDictionary setObject: oauthToken forKey: @"TempOAuthToken"] ;
			}
			NSRange oauthVerifierRange = [response rangeOfString: @"oauth_verifier="] ;
			if (oauthVerifierRange.length > 0)
			{
				NSString *oauthIdentifier ;
				int fromIndex = oauthVerifierRange.location + oauthVerifierRange.length ;
				oauthIdentifier = [response substringFromIndex: fromIndex] ;
				oauthIdentifier = [oauthIdentifier stringByReplacingPercentEscapesUsingEncoding: NSUTF8StringEncoding] ;
				
				// we print the token and build a dictionary that we return
				[responseDictionary setObject: oauthIdentifier forKey: @"TempOAuthIdentifier"] ;
			}
			return [responseDictionary autorelease] ;
		}
	}
	
	return nil ;
}

- (void)validateOAuthToken:(NSString *)tempOAuthToken withIdentifier:(NSString *)tempOAuthIdentifier
{
	
    if (tempOAuthToken==nil || tempOAuthIdentifier==nil)
        return;
    
    NSString *URL =  kSPCBaseURL@"oauth/token" ;
	
    
    
    NSString *oauth_header =  [OAuthSign generateOAuthAuthorizationHeaderForMethod:@"POST"
                                                                               URL:URL
                                                                          callback:nil
                                                                       consumerKey:SKYROCK_CONSUMER_KEY 
                                                                 consumerKeySecret:SKYROCK_CONSUMER_SECRET 
                                                                             token:tempOAuthToken
                                                                       tokenSecret:self.p_secretToken
                                                                          verifier:tempOAuthIdentifier                                                  postParameters:nil];
    
	ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL: [NSURL URLWithString: URL]] ;
	[request setRequestMethod: @"POST"] ;
    
	[request addRequestHeader: @"Authorization" value: oauth_header] ;
	[request setDidStartSelector: @selector(requestOAuthStarted:)] ;
	[request setDidFinishSelector: @selector(requestOAuthFinished:)] ;
	[request setDidFailSelector: @selector(requestOAuthFailed:)] ;
	[request setDelegate: self] ;
    [self _setRequestType:SPC_RequestTypeValidationToken toRequest:request];
    
	[request startAsynchronous] ;
    
    self.p_initialToken = nil;
    self.p_secretToken = nil;
    
}






#pragma mark - oAuth delegate

- (void)requestOAuthStarted:(ASIHTTPRequest *)request
{
	SkyLog(@"Send to %@", request.url);
}

- (void)requestOAuthFinished:(ASIHTTPRequest *)request
{
    NSInteger requestType = [self _retreiveRequestTypeForRequest:request];
    
    SkyLog(@"REP : %@", [request responseString]);
    
    
	if (requestType == SPC_RequestTypeInitialToken)
	{
		if ([request error])
		{
			// dismiss the login dialog
			[loginDialog dismissAnimated: YES] ;
			
			// we send a shout to the delegate that the authentication failed
			NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 5 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the initial token failed." forKey: NSLocalizedDescriptionKey]] ;
			if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
				[delegate socialClient: self authenticationDidFailWithError: error] ;
		}
		else
		{
            
			NSArray *responseBodyComponents = [[request responseString] componentsSeparatedByString: @"&"] ;
			NSString *theToken = nil ;
			NSString *theTokenSecret = nil ;
			for (NSString *component in responseBodyComponents)
			{
				NSArray *subComponents = [component componentsSeparatedByString: @"="] ;
				if ([[subComponents objectAtIndex: 0] isEqualToString: @"oauth_token"])
					theToken = [subComponents objectAtIndex: 1] ;
				if ([[subComponents objectAtIndex: 0] isEqualToString: @"oauth_token_secret"])
					theTokenSecret = [subComponents objectAtIndex: 1] ;
                
                if (theToken && theTokenSecret) {
                    
					// we have our initial token, we can now show the login dialog
                    self.p_initialToken = theToken;
                    self.p_secretToken = theTokenSecret;
                    
					[self showLoginDialog] ;
					return ;
                    
                }
                
			}            
            
			// if we reach this point, this is an authentication error...
			// dismiss the login dialog
			[loginDialog dismissAnimated: YES] ;
			
			// we send a shout to the delegate that the authentication failed
			NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 5 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the initial token failed." forKey: NSLocalizedDescriptionKey]] ;
			if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
				[delegate socialClient: self authenticationDidFailWithError: error] ;
		}
	}
	else if (requestType == SPC_RequestTypeValidationToken)
	{
		if ([request error])
		{
			// dismiss the login dialog
			[loginDialog dismissAnimated: YES] ;
			
			// we send a shout to the delegate that the authentication failed
			NSError *error = [NSError errorWithDomain: DDAuthenticationError code: 6 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the OAuth token failed." forKey: NSLocalizedDescriptionKey]] ;
			if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
				[delegate socialClient: self authenticationDidFailWithError: error] ;
		}
		else
		{
			NSArray *responseBodyComponents = [[request responseString] componentsSeparatedByString: @"&"] ;
			NSString *theToken = nil ;
			NSString *theTokenSecret = nil ;
			for (NSString *component in responseBodyComponents)
			{
				NSArray *subComponents = [component componentsSeparatedByString: @"="] ;
				if ([[subComponents objectAtIndex: 0] isEqualToString: @"oauth_token"])
					theToken = [subComponents objectAtIndex: 1] ;
				if ([[subComponents objectAtIndex: 0] isEqualToString: @"oauth_token_secret"])
					theTokenSecret = [subComponents objectAtIndex: 1] ;
			}
			
			if (theToken)
			{
				// we create a token, and store it
				OAuthToken *newToken = [[[OAuthToken alloc] initWithService: [[self class] clientServiceKey] andKey: theToken andSecret: theTokenSecret] autorelease] ;
				[self setToken: newToken] ;
				[self.token store] ;
				// we give a shout to the delegate
				if (delegate && [delegate respondsToSelector: @selector(socialClientAuthenticationDidSucceed:)])
					[delegate performSelectorOnMainThread: @selector(socialClientAuthenticationDidSucceed:) withObject: self waitUntilDone: NO] ;
				// and close the login dialog
				[loginDialog dismissAnimated: YES] ;
                
                
                if (self.p_typeRestart>SPC_RequestTypeToRestart) {
                    switch (self.p_typeRestart) {
                        case SPC_RequestTypeGetUser:
                            [self getUserData];
                            break;
                            
                        case SPC_RequestTypeBlogArticle:
                            [self _postBlogArticle:self.p_argRestart];
                            break;
                        case SPC_RequestTypeBlogPhoto:
                            [self _postBlogPhoto:self.p_argRestart];
                            break;
                            
                        case SPC_RequestTypeProfilePhoto:
                            [self postProfilePhoto:self.p_argRestart];
                            break;
                            
                        case SPC_RequestTypeUpdateStatus:
                            [self updateStatus:self.p_argRestart];
                            break;
                            
                        default:
                            break;
                    } 
                    
                    self.p_argRestart = nil;
                    self.p_typeRestart = 0;
                    
                }
                
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
	}
	
}

- (void)requestOAuthFailed:(ASIHTTPRequest *)request
{
    NSInteger requestType = [self _retreiveRequestTypeForRequest:request];
	
	if (requestType == SPC_RequestTypeInitialToken || requestType == SPC_RequestTypeValidationToken)
	{
		// dismiss the login dialog
		[loginDialog dismissAnimated: YES] ;
		
        SkyLog(@"FAILED !!! %@", [request responseStatusMessage]);
        
		// we send a shout to the delegate that the authentication failed
		NSError *error ;
		if ([[request.error domain] isEqualToString: @"ASIHTTPRequestErrorDomain"] && [request.error code] == 2)
			error = [NSError errorWithDomain: DDAuthenticationError code: 2 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request timed out." forKey: NSLocalizedDescriptionKey]] ;
		else if (requestType == SPC_RequestTypeInitialToken)
			error = [NSError errorWithDomain: DDAuthenticationError code: 5 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the initial token failed." forKey: NSLocalizedDescriptionKey]] ;
		else if (requestType == SPC_RequestTypeValidationToken)
			error = [NSError errorWithDomain: DDAuthenticationError code: 6 userInfo: [NSDictionary dictionaryWithObject: @"The authentication failed because the request for the OAuth token failed." forKey: NSLocalizedDescriptionKey]] ;
        
		if (delegate && [delegate respondsToSelector: @selector(socialClient:authenticationDidFailWithError:)])
			[delegate socialClient: self authenticationDidFailWithError: error] ;
	}
	
}


#pragma mark - API Skyrock

#define kSPC_USER @"user/get.json"
#define kSPC_MOOD @"mood/set_mood.json"
#define kSPC_AVATAR @"profile/add_picture.json"
#define kSPC_BLOG @"blog/new_post.json"


-(void) _postBlogPhoto:(NSArray*)args
{
    if (args.count==2) {        
        [self postBlogPhoto:[args objectAtIndex:0] withTitle:[args objectAtIndex:1]];
    }
}

-(void) _postBlogArticle:(NSArray*)args
{
    if (args.count==2) {        
        [self postBlogArticle:[args objectAtIndex:0] withTitle:[args objectAtIndex:1]];
    }    
}


#define kSPC_Title @"title"
#define kSPC_Content @"text"
#define kSPC_ImageData @"imageData"



-(ASIFormDataRequest*) _getBlogRequestFor:(NSDictionary*)infos
{
    
    NSURL* url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", kSPCBaseURL, kSPC_BLOG]];    
    SkyLog(@"will send to |%@|", [url absoluteString]);    
    
    ASIFormDataRequest* r = [ASIFormDataRequest requestWithURL:url];
    
    [r addRequestHeader:@"Accept" value:@"application/json"];
    [r addRequestHeader:@"Content-type" value:@"application/json"];
    [r setRequestMethod:@"POST"];    
    
    
    NSString* title = [infos objectForKey:kSPC_Title];
    NSString* text = [infos objectForKey:kSPC_Content];
    NSData* imgData = [infos objectForKey:kSPC_ImageData];
    
    
    [r addPostValue:title forKey:@"title"]; 
    if (text)
        [r addPostValue:text forKey:@"text"]; 
    else
        [r addPostValue:@"\n" forKey:@"text"]; 
    
    if (imgData) {        
        [r addData:imgData withFileName:@"photo.jpg" andContentType:@"image/jpeg" forKey:@"media_file"];            
        [r addPostValue:@"image" forKey:@"media_type"];        
    }
    
    NSString* oAuthHeader = [self oauthHeaderForUrl:[url absoluteString] isPost:YES postParams:nil];
    [r addRequestHeader:@"Authorization" value:oAuthHeader];    
    
	[r setDidStartSelector: @selector(requestAPIStarted:)] ;
	[r setDidFinishSelector: @selector(requestAPIFinished:)] ;
	[r setDidFailSelector: @selector(requestAPIFailed:)] ;
    
    [r setDelegate:self];
    [url release];       
    
    return r;
}


-(void) postBlogPhoto:(UIImage*)image withTitle:(NSString*)title;
{
    NSData* imgData = UIImageJPEGRepresentation(image, .8f);
    
	if (image == nil || imgData==nil || imgData.length == 0)
	{
		if ([self.delegate respondsToSelector:@selector(SkyrockClientPostBlogPhotoFailedWithError:)]) {
            NSError* error = [NSError errorWithDomain:DDSocialClientError 
                                                 code:3 
                                             userInfo:[NSDictionary dictionaryWithObject:@"Image not valid" forKey:NSLocalizedDescriptionKey]];
            
            [self.delegate SkyrockClientPostBlogPhotoFailedWithError:error];
        }
        
		return ;
	}  
    
    if (title==nil)
        title = @"";
    
    self.p_argRestart = [NSArray arrayWithObjects:image,title,nil];
    self.p_typeRestart = SPC_RequestTypeBlogPhoto;
    
	if (![self serviceHasValidToken] || [self.token hasExpired])
    {
		[self login];
		return;
	}    
    
    
    NSDictionary* infos = [NSDictionary dictionaryWithObjectsAndKeys:title, kSPC_Title,imgData, kSPC_ImageData, nil];
    ASIFormDataRequest* r = [self _getBlogRequestFor:infos];
    [self _setRequestType:SPC_RequestTypeBlogPhoto toRequest:r];    
    [r startAsynchronous];   
    
}


-(void) postBlogArticle:(NSString*)text withTitle:(NSString*)title;
{
    if (text==nil)
        text = @"";
    if (title==nil)
        title = @"";
    
    self.p_argRestart = [NSArray arrayWithObjects:text,title,nil];
    self.p_typeRestart = SPC_RequestTypeBlogArticle;
    
	if (![self serviceHasValidToken] || [self.token hasExpired])
    {
		[self login];
		return;
	}    
    
    
    NSDictionary* infos = [NSDictionary dictionaryWithObjectsAndKeys:title, kSPC_Title,text, kSPC_Content, nil];
    ASIFormDataRequest* r = [self _getBlogRequestFor:infos];
    [self _setRequestType:SPC_RequestTypeBlogArticle toRequest:r];    
    [r startAsynchronous];   
    
    
}



-(void) _configBasePostToRequest:(ASIHTTPRequest*) r
{
    [r addRequestHeader:@"Accept" value:@"application/json"];
    [r addRequestHeader:@"Content-type" value:@"application/json"];
    [r setRequestMethod:@"POST"];    
    
	[r setDidStartSelector: @selector(requestAPIStarted:)] ;
	[r setDidFinishSelector: @selector(requestAPIFinished:)] ;
	[r setDidFailSelector: @selector(requestAPIFailed:)] ;
    
    [r setDelegate:self];    
}


-(void) postProfilePhoto:(UIImage*)image
{
    NSData* imgData = UIImageJPEGRepresentation(image, .8f);
    
	if (image == nil || imgData==nil || imgData.length == 0)
	{
		if ([self.delegate respondsToSelector:@selector(SkyrockClientPostProfilePhotoFailedWithError:)]) {
            NSError* error = [NSError errorWithDomain:DDSocialClientError 
                                                 code:3 
                                             userInfo:[NSDictionary dictionaryWithObject:@"Image not valid" forKey:NSLocalizedDescriptionKey]];
            
            [self.delegate SkyrockClientPostProfilePhotoFailedWithError:error];
        }
        
		return ;
	}        
    
    self.p_argRestart = image;
    self.p_typeRestart = SPC_RequestTypeProfilePhoto;
    
	if (![self serviceHasValidToken] || [self.token hasExpired])
    {
		[self login];
		return;
	}    
    
    
    NSURL* url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", kSPCBaseURL, kSPC_AVATAR]];    
    SkyLog(@"will send to |%@|", [url absoluteString]);    
    
    ASIFormDataRequest* r = [ASIFormDataRequest requestWithURL:url];
    
    [self _configBasePostToRequest:r];
    
    [r addPostValue:[NSNumber numberWithInt:1] forKey:@"id_album"]; 
    [r addPostValue:[NSNumber numberWithInt:1] forKey:@"as_main"]; 
    [r addData:imgData withFileName:@"photo.jpg" andContentType:@"image/jpeg" forKey:@"picture"];    
    
    NSString* oAuthHeader = [self oauthHeaderForUrl:[url absoluteString] isPost:YES postParams:nil];
    [r addRequestHeader:@"Authorization" value:oAuthHeader];    
    
    [self _setRequestType:SPC_RequestTypeProfilePhoto toRequest:r];    
    
    [r startAsynchronous];   
    [url release];        
    
    
}

-(void) updateStatus:(NSString*)text
{
    
	if (text == nil || text.length == 0 || text.length>140)
	{
		if ([self.delegate respondsToSelector:@selector(SkyrockClientUpdateStatusFailedWithError:)]) {
            NSError* error = [NSError errorWithDomain:DDSocialClientError 
                                                 code:3 
                                             userInfo:[NSDictionary dictionaryWithObject:@"Status length must be between 1 and 140" forKey:NSLocalizedDescriptionKey]];
            
            [self.delegate SkyrockClientUpdateStatusFailedWithError:error];
        }
        
		return ;
	}    
    
    
    
    self.p_argRestart = text;
    self.p_typeRestart = SPC_RequestTypeUpdateStatus;
    
	if (![self serviceHasValidToken] || [self.token hasExpired])
    {
		[self login];
		return;
	}    
    
    
    NSURL* url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", kSPCBaseURL, kSPC_MOOD]];    
    SkyLog(@"will send to |%@|", [url absoluteString]);    
    
    ASIHTTPRequest* r = [ASIHTTPRequest requestWithURL:url];    
    
    [self _configBasePostToRequest:r];
    
    NSDictionary* infoPOST = [NSDictionary dictionaryWithObject:text forKey:@"message"];    
    
    if (infoPOST) {    
        NSString* jsonPost = [infoPOST JSONRepresentation];        
        [r setPostBody:[NSMutableData dataWithData:[jsonPost dataUsingEncoding:NSUTF8StringEncoding]]];
    }
    
    NSString* oAuthHeader = [self oauthHeaderForUrl:[url absoluteString] isPost:YES postParams:infoPOST];
    
    [r addRequestHeader:@"Authorization" value:oAuthHeader];    
    
    [self _setRequestType:SPC_RequestTypeUpdateStatus toRequest:r];    
    
    [r startAsynchronous];   
    [url release];        
    
    
}


-(void) getUserData
{
    self.p_argRestart = nil;
    self.p_typeRestart = SPC_RequestTypeGetUser;
    
	if (![self serviceHasValidToken] || [self.token hasExpired])
    {
		[self login];
		return;
	}    
    
    
    NSURL* url = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"%@%@", kSPCBaseURL, kSPC_USER]];    
    SkyLog(@"will send to |%@|", [url absoluteString]);    
    
    ASIHTTPRequest* r = [ASIHTTPRequest requestWithURL:url];
    
    [r addRequestHeader:@"Accept" value:@"application/json"];       
    [r setRequestMethod:@"GET"];
    
    NSString* oAuthHeader = [self oauthHeaderForUrl:[url absoluteString] isPost:NO postParams:nil];
    
    [r addRequestHeader:@"Authorization" value:oAuthHeader];    
    
	[r setDidStartSelector: @selector(requestAPIStarted:)] ;
	[r setDidFinishSelector: @selector(requestAPIFinished:)] ;
	[r setDidFailSelector: @selector(requestAPIFailed:)] ;
    
    [r setDelegate:self];
    [self _setRequestType:SPC_RequestTypeGetUser toRequest:r];    
    
    [r startAsynchronous];   
    [url release];    
    
}



#pragma mark - API Delegate


- (void)requestAPIStarted:(ASIHTTPRequest *)request
{
    SkyLog(@"Send to %@", request.url);
}

- (void)requestAPIFinished:(ASIHTTPRequest *)request
{
    NSInteger requestType = [self _retreiveRequestTypeForRequest:request]; 
    
    NSString* response = [request responseString];    
    int status = [request responseStatusCode];        
    
    SkyLog(@"REP : %@", response);    
    
    switch (requestType) {
        case SPC_RequestTypeGetUser:
        {         
            if (status==200) { 
                
                NSDictionary* infos = [response JSONValue];
                if ([infos isKindOfClass:[NSDictionary class]] && infos.count>0) {
                    if ([self.delegate respondsToSelector:@selector(SkyrockClientUserData:)]) 
                        [self.delegate SkyrockClientUserData:infos];
                    return;
                }
            }
            
            if ([self.delegate respondsToSelector:@selector(SkyrockClientUserDataFailedWithError:)]) {    
                NSString* errStr = [NSString stringWithFormat:@"Get user data failed [%d]", status];
                
                NSError *error = [NSError errorWithDomain:DDSocialClientError 
                                                     code:4 
                                                 userInfo:[NSDictionary dictionaryWithObject:errStr forKey:NSLocalizedDescriptionKey]];
                [self.delegate SkyrockClientUpdateStatusFailedWithError:error];
            }
            
            break;
        }   
        case SPC_RequestTypeUpdateStatus:
        {
            
            if (status==200) { 
                BOOL ok = [response boolValue];
                if (ok) {
                    if ([self.delegate respondsToSelector:@selector(SkyrockClientUpdateStatusSucceed)])
                        [self.delegate SkyrockClientUpdateStatusSucceed];
                    return;
                }
            }
            
            if ([self.delegate respondsToSelector:@selector(SkyrockClientUpdateStatusFailedWithError:)]) {                    
                NSString* errStr = nil;
                
                if (status==400) {
                    NSDictionary* d = [response JSONValue];
                    errStr = [d objectForKey:@"error"];                
                }
                else 
                    errStr = [NSString stringWithFormat:@"Post to Skyrock.com failed [%d]", status];
                
                NSError *error = [NSError errorWithDomain:DDSocialClientError 
                                                     code:4 
                                                 userInfo:[NSDictionary dictionaryWithObject:errStr forKey:NSLocalizedDescriptionKey]];
                [self.delegate SkyrockClientUpdateStatusFailedWithError:error];
            }
            
            
            break;
        }   
        case SPC_RequestTypeProfilePhoto:
        {
            if (status==200) { 
                
                NSDictionary* infos = [response JSONValue];                
                if ([infos isKindOfClass:[NSDictionary class]] && infos.count>0) {                
                    if ([self.delegate respondsToSelector:@selector(SkyrockClientPostProfilePhotoSucceed)])
                        [self.delegate SkyrockClientPostProfilePhotoSucceed];                    
                    return;
                }
            }
            
            if ([self.delegate respondsToSelector:@selector(SkyrockClientPostProfilePhotoFailedWithError:)]) {    
                NSString* errStr = [NSString stringWithFormat:@"Post profile photo failed [%d]", status];
                
                NSError *error = [NSError errorWithDomain:DDSocialClientError 
                                                     code:4 
                                                 userInfo:[NSDictionary dictionaryWithObject:errStr forKey:NSLocalizedDescriptionKey]];
                [self.delegate SkyrockClientPostProfilePhotoFailedWithError:error];
            }            
            
            
            break;
        }
        case SPC_RequestTypeBlogArticle:
        {
            if (status==200) {     
                
                NSDictionary* infoReceived = [response JSONValue];             
                NSString* postURL = [infoReceived objectForKey:@"post_url"];
                
                if (postURL.length>0) {
                    if ([self.delegate respondsToSelector:@selector(SkyrockClientPostBlogArticleSucceedWithURL:)])
                        [self.delegate SkyrockClientPostBlogArticleSucceedWithURL:postURL];
                    return;
                }                
            }
            
            if ([self.delegate respondsToSelector:@selector(SkyrockClientPostBlogArticleFailedWithError:)]) {    
                NSString* errStr = [NSString stringWithFormat:@"Post blog article failed [%d]", status];
                
                NSError *error = [NSError errorWithDomain:DDSocialClientError 
                                                     code:4 
                                                 userInfo:[NSDictionary dictionaryWithObject:errStr forKey:NSLocalizedDescriptionKey]];
                [self.delegate SkyrockClientPostBlogArticleFailedWithError:error];
            }                
            
            break; 
        }
        case SPC_RequestTypeBlogPhoto:
        {
            if (status==200) {     
                
                NSDictionary* infoReceived = [response JSONValue];             
                NSString* postURL = [infoReceived objectForKey:@"post_url"];
                
                if (postURL.length>0) {
                    if ([self.delegate respondsToSelector:@selector(SkyrockClientPostBlogPhotoSucceedWithURL:)])
                        [self.delegate SkyrockClientPostBlogPhotoSucceedWithURL:postURL];
                    return;
                }                
            }
            
            if ([self.delegate respondsToSelector:@selector(SkyrockClientPostBlogPhotoFailedWithError:)]) {    
                NSString* errStr = [NSString stringWithFormat:@"Post blog photo failed [%d]", status];
                
                NSError *error = [NSError errorWithDomain:DDSocialClientError 
                                                     code:4 
                                                 userInfo:[NSDictionary dictionaryWithObject:errStr forKey:NSLocalizedDescriptionKey]];
                [self.delegate SkyrockClientPostBlogPhotoFailedWithError:error];
            }                
            
            break; 
        }            
        default:
            break;
    }
}

- (void)requestAPIFailed:(ASIHTTPRequest *)request
{
    NSInteger requestType = [self _retreiveRequestTypeForRequest:request];    
    SkyLog(@"REP : %@", [request responseString]);    
    
    NSInteger statusCode = [request responseStatusCode];
    
    if (statusCode == 401) {
        [DDSkyrockClient logout];
        [self login];
    }
    else {
        
        NSError *error ;
        if ([[request.error domain] isEqualToString: @"ASIHTTPRequestErrorDomain"] && [request.error code] == 2)
            error = [NSError errorWithDomain:DDSocialClientError 
                                        code:2 
                                    userInfo:[NSDictionary dictionaryWithObject:@"The request timed out." forKey:NSLocalizedDescriptionKey]];
        else
            error = [NSError errorWithDomain:DDSocialClientError 
                                        code:0 
                                    userInfo:[NSDictionary dictionaryWithObject:@"Unknown error." forKey: NSLocalizedDescriptionKey]];    
        
        switch (requestType) {
            case SPC_RequestTypeGetUser:
            {
                if ([self.delegate respondsToSelector:@selector(SkyrockClientUserDataFailedWithError:)])                 
                    [self.delegate SkyrockClientUserDataFailedWithError:error];
                break;
            }                
                
            case SPC_RequestTypeProfilePhoto:
            {
                if ([self.delegate respondsToSelector:@selector(SkyrockClientPostProfilePhotoFailedWithError:)])                 
                    [self.delegate SkyrockClientPostProfilePhotoFailedWithError:error];
                break;
            }
                
            case SPC_RequestTypeUpdateStatus:
            {
                if ([self.delegate respondsToSelector:@selector(SkyrockClientUpdateStatusFailedWithError:)])                 
                    [self.delegate SkyrockClientUpdateStatusFailedWithError:error];
                break;
            }
                
            case SPC_RequestTypeBlogPhoto:
            {
                if ([self.delegate respondsToSelector:@selector(SkyrockClientPostBlogPhotoFailedWithError:)])                 
                    [self.delegate SkyrockClientPostBlogPhotoFailedWithError:error];
                break;
            }
                
            case SPC_RequestTypeBlogArticle:
            {
                if ([self.delegate respondsToSelector:@selector(SkyrockClientPostBlogArticleFailedWithError::)])                 
                    [self.delegate SkyrockClientPostBlogArticleFailedWithError:error];
                break;
            }
                
            default:
                break;
        }
        
    }
    
}



@end
