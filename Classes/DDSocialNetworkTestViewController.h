//
//  DDSocialNetworkTestViewController.h
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 03/03/2010.
//  Copyright Damien DeVille 2010. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "DDSocialNetworkClient.h"
#import "DDFacebookClient.h"
#import "DDTwitterClient.h"
#import "DDFlickrClient.h"

typedef enum
{
	UploadingNone,
	UploadingText,
	UploadingTextAndImage,
}
Uploading ;


@interface DDSocialNetworkTestViewController : UIViewController <UIImagePickerControllerDelegate, UINavigationControllerDelegate, DDSocialNetworkClientDelegate>
{
	IBOutlet UITextView *_logs ;
	IBOutlet UITextField *_message ;
	IBOutlet UIImageView *_photo ;
	IBOutlet UIButton *_sendMessage ;
	IBOutlet UIButton *_sendMessageAndPhoto ;
	IBOutlet UIButton *_forgetCredentials ;

	DDFacebookClient *_client ;
	//DDTwitterClient *_client ;
	//DDFlickrClient *_client ;
	
	Uploading _uploading ;
}

- (IBAction)forgetCredential ;
- (IBAction)send:(id)sender ;
- (IBAction)takePhoto ;
- (IBAction)selectPhoto ;

- (void)post ;
- (void)appendToLog:(NSString *)message ;

@end
