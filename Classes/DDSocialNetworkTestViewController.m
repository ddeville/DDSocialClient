//
//  DDSocialNetworkTestViewController.m
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 03/03/2010.
//  Copyright Damien DeVille 2010. All rights reserved.
//

#import "DDSocialNetworkTestViewController.h"
#import "DDSocialNetworkClientAppDelegate.h"
#import <MobileCoreServices/MobileCoreServices.h> // for types

#import "DDSocialNetworkClientLoginDialog.h"

@implementation DDSocialNetworkTestViewController


- (void)viewDidAppear:(BOOL)animated
{
//	_client = [[DDFacebookClient alloc] initWithDelegate: self] ;
//	_client = [[DDTwitterClient alloc] initWithDelegate: self] ;
//	_client = [[DDFlickrClient alloc] initWithDelegate: self] ;
	_client = [[DDLinkedInClient alloc] initWithDelegate: self] ;
}



- (IBAction)send:(id)sender
{
	if (!_client)
	{
		[self appendToLog: @"Warning: no client object created"] ;
		return ;
	}
	
	_uploading = (sender == _sendMessage) ? UploadingText : UploadingTextAndImage ;
	
	[self post] ;
}



- (IBAction)forgetCredential
{
	[[_client class] logout] ;
	[self appendToLog: @"Delete the token"] ;
}



- (IBAction)takePhoto
{
	if(![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera])
	{
		[self appendToLog: @"No camera available."] ;
		return ;
	}
	UIImagePickerController *picker = [[UIImagePickerController alloc] init] ;
	[picker setDelegate: self] ;
	[picker setSourceType: UIImagePickerControllerSourceTypeCamera] ;
	[self presentModalViewController: picker animated: YES] ;
	[picker release] ;
}



- (IBAction)selectPhoto
{
	UIImagePickerController *picker = [[UIImagePickerController alloc] init] ;
	[picker setDelegate: self] ;
	[picker setSourceType: UIImagePickerControllerSourceTypeSavedPhotosAlbum] ;
	[self presentModalViewController: picker animated: YES] ;
	[picker release] ;
}



- (void)post
{
	if( !_client || (_uploading == UploadingNone) )
		return ;
	
	switch(_uploading)
	{
		case UploadingText:
			//[_client postMessage: @"small API test" visibilityConnectionsOnly: NO] ;
			//[_client postLinkWithTitle: @"a title" andLink: @"http://www.apple.com" andLinkImage: @"http://hothardware.com/newsimages/Item8124/apple-logo.jpg" andLinkDescription: @"a description" visibilityConnectionsOnly: NO] ;
			[_client postMessage: @"small test" withLinkTitle: @"a title" andLink: @"http://www.apple.com" andLinkImage: @"http://hothardware.com/newsimages/Item8124/apple-logo.jpg" andLinkDescription: @"a description" visibilityConnectionsOnly: NO] ;
			
			//[_client getListOfGalleries] ;
			//[_client getUserInfo] ;
			//[_client createGallery: @"damien" withDescription: @"ciao bella"] ;
			//[_client postImage: @"4883410620" toGallery: @"52841807-72157624580146587" withComment: @"ciao"] ;
			//[_client getListOfPhotosets] ;
			//[_client createPhotoset: @"ciao bella" withDescription: @"ahooo" withPrimaryPhoto: @"4883410620"] ;
			//[_client postImage: @"4876529455" toPhotoset: @"72157624580399559"] ;
			
			//[_client updateFacebookStatus: _message.text] ;
			//[_client postMessageToTwitter: _message.text] ;
			
			//[_client postMessageToTwitter: @"testing some operation queue stuff and other borinf stuff you do not want to know about that is why Twitter will cut all the additional shit for us!"] ;
			//[_client postMessageToTwitter: @"testing some operation queue stuff and other borinf stuff you do not want to know about that is why Twitter will cut all the additional shit for us!" withURL: @"http://www.ddeville.me"] ;
			break ;
		case UploadingTextAndImage:
			//[_client postImageToFlickr: _photo.image withTitle: _message.text andDescription: @"boh"] ;
			
			//[_client postPhotoToFacebook: _photo.image withCaption: _message.text] ;
			//[_client postPhotoToFacebook: _photo.image withCaption: _message.text] ;
			
			//[_client postImageToTwitter: _photo.image withMessage: @"testing some operation queue stuff and other borinf stuff you do not want to know about that is why Twitter will cut all the additional shit for us!"] ;
			//[_client postImageToTwitter: _photo.image withMessage: _message.text] ;
		default:
			break ;
	}
}



- (void)appendToLog:(NSString *)message
{
	if(_logs.text && [_logs.text length])
	{
		_logs.text = [NSString stringWithFormat: @"%@\n%@", _logs.text, message] ;
	}
	else
	{
		_logs.text = message ;
	}
}	

























#pragma mark -
#pragma mark DDSocialNetworkClient delegate methods

- (BOOL)shouldDisplayLoginDialogForSocialMediaClient:(DDSocialNetworkClient *)client
{
	return YES ;
}


- (UIViewController *)rootViewControllerForDisplayingLoginDialogForSocialMediaClient:(DDSocialNetworkClient *)client
{
	DDSocialNetworkClientAppDelegate *ad = [[UIApplication sharedApplication] delegate] ;
	return ad.viewController ;
}


-(void)socialMediaClientAuthenticationDidSucceed:(DDSocialNetworkClient *)client
{
	[self appendToLog: @"Success: Authentication did succeed"] ;
	
	// we might want to do the posting now!
//	[self post] ;
}



-(void)socialMediaClient:(DDSocialNetworkClient *)client authenticationDidFailWithError:(NSError *)error
{
	[self appendToLog: [NSString stringWithFormat: @"Error: %@", [[error userInfo] objectForKey: @"info"]]] ;
	_uploading = UploadingNone ;
}








#pragma mark -
#pragma mark DDFacebookClient delegate methods

- (void)facebookGotResponse:(NSMutableDictionary *)response forRequestType:(DDFacebookRequestType)requestType
{
	[self appendToLog: @"Facebook got a response"] ;
}



- (void)facebookRequest:(DDFacebookRequestType)requestType failedWithError:(NSError *)error
{
	[self appendToLog: [NSString stringWithFormat: @"Error: %@", [[error userInfo] objectForKey: @"info"]]] ;
}



- (void)facebookPostDidSucceed:(DDFacebookPostType)postType andReturned:(NSMutableDictionary *)response
{
	[self appendToLog: @"Facebook post succeded"] ;
}



- (void)facebookPost:(DDFacebookPostType)postType failedWithError:(NSError *)error
{
	[self appendToLog: [NSString stringWithFormat: @"Error: %@", [[error userInfo] objectForKey: @"info"]]] ;
}







#pragma mark -
#pragma mark DDTwitterClient delegate methods

- (void)twitterPostDidSucceedAndReturned:(NSMutableDictionary *)response
{
	[self appendToLog: @"Twitter post succeded"] ;
}



- (void)twitterPostFailedWithError:(NSError *)error
{
	[self appendToLog: [NSString stringWithFormat: @"Error: %@", [[error userInfo] objectForKey: @"info"]]] ;
}





#pragma mark -
#pragma mark DDFlickrClient delegate methods

- (void)flickrPost:(DDFlickrPostType)postType didSucceedAndReturned:(NSMutableDictionary *)response ;
{
	[self appendToLog: @"Flickr post succeded"] ;
}



- (void)flickrPost:(DDFlickrPostType)postType failedWithError:(NSError *)error ;
{
	[self appendToLog: [NSString stringWithFormat: @"Error: %@", [[error userInfo] objectForKey: @"info"]]] ;
}




#pragma mark -
#pragma mark DDLinkedInClient delegate methods

- (void)linkedInPostDidSucceed:(DDLinkedInPostType)type
{
	[self appendToLog: @"LinkedIn post succeded"] ;
}


- (void)linkedInPost:(DDLinkedInPostType)type failedWithError:(NSError *)error
{
	[self appendToLog: [NSString stringWithFormat: @"Error: %@", [[error userInfo] objectForKey: @"info"]]] ;
}









#pragma mark -
#pragma mark Photo picker delegate methods

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	NSString *mediaType ;
	UIImage *image ;
	
	[picker dismissModalViewControllerAnimated: YES] ;
	
	mediaType = [info objectForKey: UIImagePickerControllerMediaType] ;
	
	if([mediaType isEqualToString: (NSString *)kUTTypeImage])
	{
		if(!(image = [info objectForKey: UIImagePickerControllerEditedImage]))
			image = [info objectForKey: UIImagePickerControllerOriginalImage] ;
		
		// display it in the image view, where we can find it when we need it
		if(image)
			_photo.image = image ;
		
	}
	else if([mediaType isEqualToString: (NSString *)kUTTypeMovie])
	{
		// we don't want videos for now...
	}
}


















#pragma mark -
#pragma mark UITextField delegate methods

-(BOOL)textFieldShouldEndEditing:(UITextField *)textField
{
	return YES ;
}



-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
	[textField resignFirstResponder] ;
	return YES ;
}



















#pragma mark -
#pragma mark Memory management methods

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning] ;
}



- (void)viewDidUnload
{
	
}



- (void)dealloc
{
	[super dealloc] ;
}

@end
