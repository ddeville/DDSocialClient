//
//  DDiPhoneViewController.m
//  SocialNetworkClient
//
//  Created by Damien DeVille on 03/03/2010.
//  Copyright Damien DeVille 2010. All rights reserved.
//

#import "DDiPhoneViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "DDFacebookClient.h"
#import "DDTwitterClient.h"
#import "DDFlickrClient.h"
#import "DDLinkedInClient.h"
#import "DDFoursquareClient.h"

@implementation DDiPhoneViewController

@synthesize segmentedControl ;
@synthesize imageView ;
@synthesize takePhotoButton ;
@synthesize selectPhotoButton ;
@synthesize messageTextField ;
@synthesize linkTextField ;
@synthesize textView ;
@synthesize imageSwitch ;
@synthesize messageSwitch ;
@synthesize linkSwitch ;

- (id)initWithCoder:(NSCoder *)aDecoder
{
	if ((self = [super initWithCoder: aDecoder]))
	{
		facebookClient = [[DDFacebookClient alloc] initWithDelegate: self] ;
		twitterClient = [[DDTwitterClient alloc] initWithDelegate: self] ;
		flickrClient = [[DDFlickrClient alloc] initWithDelegate: self] ;
		linkedInClient = [[DDLinkedInClient alloc] initWithDelegate: self] ;
		foursquareClient = [[DDFoursquareClient alloc] initWithDelegate: self] ;
	}
	
	return self ;
}

- (void)dealloc
{
	[segmentedControl release], segmentedControl = nil ;
	[imageView release], imageView = nil ;
	[takePhotoButton release], takePhotoButton = nil ;
	[selectPhotoButton release], selectPhotoButton = nil ;
	[messageTextField release], messageTextField = nil ;
	[linkTextField release], linkTextField = nil ;
	[textView release], textView = nil ;
	[imageSwitch release], imageSwitch = nil ;
	[messageSwitch release], messageSwitch = nil ;
	[linkSwitch release], linkSwitch = nil ;
	
	[facebookClient release], facebookClient = nil ;
	[twitterClient release], twitterClient = nil ;
	[flickrClient release], flickrClient = nil ;
	[linkedInClient release], linkedInClient = nil ;
	
	[super dealloc] ;
}

- (void)viewDidLoad
{
	[super viewDidLoad] ;
	
	[imageSwitch setOn: NO] ;
	[messageSwitch setOn: YES] ;
	[linkSwitch setOn: NO] ;
}

- (void)viewDidUnload
{
	[super viewDidUnload] ;
}

- (void)appendToLog:(NSString *)message
{
	if(textView.text && [textView.text length])
		[textView setText: [NSString stringWithFormat: @"%@\n%@", textView.text, message]] ;
	else
		[textView setText: message] ;
}

- (IBAction)segmentedControlValueChanged:(id)sender
{
	switch (segmentedControl.selectedSegmentIndex)
	{
		case 0:
			break ;
		case 1:
			break ;
		case 2:
			break ;
		case 3:
			break ;
		case 4:
			break ;
		default:
			break ;
	}
}

- (IBAction)takePhotoButtonClicked:(id)sender
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

- (IBAction)selectPhotoButtonClicked:(id)sender
{
	UIImagePickerController *picker = [[UIImagePickerController alloc] init] ;
	[picker setDelegate: self] ;
	[picker setSourceType: UIImagePickerControllerSourceTypeSavedPhotosAlbum] ;
	[self presentModalViewController: picker animated: YES] ;
	[picker release] ;
}

- (IBAction)loginButtonClicked:(id)sender
{
	switch (segmentedControl.selectedSegmentIndex)
	{
		case 0:
			[facebookClient login] ;
			break ;
		case 1:
			[twitterClient login] ;
			break ;
		case 2:
			[flickrClient login] ;
			break ;
		case 3:
			[linkedInClient login] ;
			break ;
		case 4:
			[foursquareClient login] ;
		default:
			break ;
	}
}

- (IBAction)logoutButtonClicked:(id)sender
{
	switch (segmentedControl.selectedSegmentIndex)
	{
		case 0:
			[DDFacebookClient logout] ;
			break ;
		case 1:
			[DDTwitterClient logout] ;
			break ;
		case 2:
			[DDFlickrClient logout] ;
			break ;
		case 3:
			[DDLinkedInClient logout] ;
			break ;
		case 4:
			[DDFoursquareClient logout] ;
		default:
			break ;
	}
}

- (IBAction)postButtonClicked:(id)sender
{
	switch (segmentedControl.selectedSegmentIndex)
	{
		case 0:
		{
			if (linkSwitch.on && imageSwitch.on)
			{
				[self appendToLog: @"You cannot post both a photo and a link"] ;
			}
			else if (linkSwitch.on)
			{
				if ([linkTextField.text length])
					[facebookClient postLinkToFacebook: linkTextField.text
											  withName: nil
										   withCaption: nil
									   withDescription: nil
										   withMessage: messageSwitch.on ? messageTextField.text : nil
										   withPicture: nil] ;
				else
					[self appendToLog: @"You need to specify a link"] ;
			}
			else if (imageSwitch.on)
			{
				if (imageView.image)
					[facebookClient postPhotoToFacebook: imageView.image withCaption: (messageSwitch.on ? messageTextField.text : nil)] ;
				else
					[self appendToLog: @"You need to add an image before posting"] ;
			}
			else if (messageSwitch.on)
			{
				if ([messageTextField.text length])
					[facebookClient updateFacebookStatus: messageTextField.text] ;
				else
					[self appendToLog: @"You need to specify a message"] ;
			}
		}
			break ;
		case 1:
		{
			if (imageSwitch.on && linkSwitch.on)
			{
				[self appendToLog: @"You cannot post both a photo and a link"] ;
			}
			else if (imageSwitch.on)
			{
				if (imageView.image)
					[twitterClient postImageToTwitter: imageView.image withMessage: (messageSwitch.on ? messageTextField.text : nil)] ;
				else
					[self appendToLog: @"You need to add an image before posting"] ;
			}
			else if (linkSwitch.on)
			{
				if ([linkTextField.text length])
					[twitterClient postMessageToTwitter: (messageSwitch.on ? messageTextField.text : nil) withURL: linkTextField.text] ;
				else
					[self appendToLog: @"You need to specify a link"] ;
			}
			else if (messageSwitch.on)
			{
				if ([messageTextField.text length])
					[twitterClient postMessageToTwitter: messageTextField.text] ;
				else
					[self appendToLog: @"You need to specify a message"] ;
			}
		}
			break ;
		case 2:
		{
			if (linkSwitch.on)
			{
				[self appendToLog: @"You cannot post a link to Flickr"] ;
			}
			else if (imageSwitch.on == NO || imageView.image == nil)
			{
				[self appendToLog: @"You need to add an image before posting"] ;
			}
			else
			{
				[flickrClient postImageToFlickr: imageView.image
									  withTitle: nil 
								 andDescription: (messageSwitch.on ? messageTextField.text : nil)] ;
			}
		}
			break ;
		case 3:
		{
			if (imageSwitch.on)
			{
				[self appendToLog: @"You cannot post an image to LinkedIn"] ;
			}
			else if (linkSwitch.on)
			{
				if ([linkTextField.text length])
				{
					[linkedInClient postMessage: (messageSwitch.on ? messageTextField.text : nil)
								  withLinkTitle: @"Title"
										andLink: linkTextField.text
								   andLinkImage: nil
							 andLinkDescription: nil
					  visibilityConnectionsOnly: NO] ;
				}
				else
					[self appendToLog: @"You need to specify a link"] ;
			}
			else if (messageSwitch.on)
			{
				if ([messageTextField.text length])
				{
					[linkedInClient postMessage: messageTextField.text visibilityConnectionsOnly: NO] ;
				}
				else
					[self appendToLog: @"You need to specify a message"] ;
			}
		}
			break ;
		case 4:
		{
			
		}
			break ;
		default:
			break ;
	}
}



#pragma mark -
#pragma mark DDSocialClient delegate methods

- (BOOL)shouldDisplayLoginForSocialClient:(DDSocialClient *)client
{
	return YES ;
}

- (void)socialClientAuthenticationDidSucceed:(DDSocialClient *)client
{
	[self appendToLog: [NSString stringWithFormat: @"Success: Authentication to %@ did succeed!", [client name]]] ;
}

- (void)socialClient:(DDSocialClient *)client authenticationDidFailWithError:(NSError *)error
{
	[self appendToLog: [NSString stringWithFormat: @"Authentication to %@ did failed...", [client name]]] ;
}



#pragma mark -
#pragma mark DDFacebookClient delegate methods

- (void)facebookPostDidSucceed:(DDFacebookPostType)postType andReturned:(NSMutableDictionary *)response
{
	[self appendToLog: @"Facebook post succeded!"] ;
}

- (void)facebookPost:(DDFacebookPostType)postType failedWithError:(NSError *)error
{
	[self appendToLog: [NSString stringWithFormat: @"Facebook post failed...\nError: %@", [[error userInfo] objectForKey: NSLocalizedDescriptionKey]]] ;
}



#pragma mark -
#pragma mark DDTwitterClient delegate methods

- (void)twitterPostDidSucceedAndReturned:(NSMutableDictionary *)response
{
	[self appendToLog: @"Twitter post succeded!"] ;
}

- (void)twitterPostFailedWithError:(NSError *)error
{
	[self appendToLog: [NSString stringWithFormat: @"Twitter post failed...\nError: %@", [[error userInfo] objectForKey: NSLocalizedDescriptionKey]]] ;
}



#pragma mark -
#pragma mark DDFlickrClient delegate methods

- (void)flickrPost:(DDFlickrPostType)postType didSucceedAndReturned:(NSMutableDictionary *)response ;
{
	[self appendToLog: @"Flickr post succeded!"] ;
}



- (void)flickrPost:(DDFlickrPostType)postType failedWithError:(NSError *)error ;
{
	[self appendToLog: [NSString stringWithFormat: @"Flickr post failed...\nError: %@", [[error userInfo] objectForKey: NSLocalizedDescriptionKey]]] ;
}



#pragma mark -
#pragma mark DDLinkedInClient delegate methods

- (void)linkedInPostDidSucceed:(DDLinkedInPostType)type
{
	[self appendToLog: @"LinkedIn post succeded!"] ;
}


- (void)linkedInPost:(DDLinkedInPostType)type failedWithError:(NSError *)error
{
	[self appendToLog: [NSString stringWithFormat: @"LinkedIn post failed...\nError: %@", [[error userInfo] objectForKey: NSLocalizedDescriptionKey]]] ;
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
#pragma mark UIImagePickerController delegate methods

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
	[self dismissModalViewControllerAnimated: YES] ;
	
	NSString *mediaType = [info objectForKey: UIImagePickerControllerMediaType] ;
	if([mediaType isEqualToString: (NSString *)kUTTypeImage])
	{
		UIImage *image ;
		if((image = [info objectForKey: UIImagePickerControllerEditedImage]) == nil)
			image = [info objectForKey: UIImagePickerControllerOriginalImage] ;
		
		// display it in the image view, where we can find it when we need it
		if(image)
			[imageView setImage: image] ;
		
	}
	else if([mediaType isEqualToString: (NSString *)kUTTypeMovie])
	{
		// we don't want videos for now...
	}
}




- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES ;
//	return (interfaceOrientation == UIInterfaceOrientationPortrait) ;
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning] ;
}

@end
