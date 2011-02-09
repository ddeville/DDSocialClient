//
//  DDiPadViewController.h
//  SocialNetworkClient
//
//  Created by Damien DeVille on 1/23/11.
//  Copyright 2011 Snappy Code. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDSocialClient.h"

@class DDFacebookClient ;
@class DDTwitterClient ;
@class DDFlickrClient ;
@class DDLinkedInClient ;

@interface DDiPadViewController : UIViewController <DDSocialClientDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, UIImagePickerControllerDelegate>
{
	IBOutlet UISegmentedControl *segmentedControl ;
	IBOutlet UIImageView *imageView ;
	IBOutlet UIButton *takePhotoButton ;
	IBOutlet UIButton *selectPhotoButton ;
	IBOutlet UITextField *messageTextField ;
	IBOutlet UITextField *linkTextField ;
	IBOutlet UITextView *textView ;
	IBOutlet UISwitch *imageSwitch ;
	IBOutlet UISwitch *messageSwitch ;
	IBOutlet UISwitch *linkSwitch ;
	
	DDFacebookClient *facebookClient ;
	DDTwitterClient *twitterClient ;
	DDFlickrClient *flickrClient ;
	DDLinkedInClient *linkedInClient ;
}

@property (nonatomic,retain) IBOutlet UISegmentedControl *segmentedControl ;
@property (nonatomic,retain) IBOutlet UIImageView *imageView ;
@property (nonatomic,retain) IBOutlet UIButton *takePhotoButton ;
@property (nonatomic,retain) IBOutlet UIButton *selectPhotoButton ;
@property (nonatomic,retain) IBOutlet UITextField *messageTextField ;
@property (nonatomic,retain) IBOutlet UITextField *linkTextField ;
@property (nonatomic,retain) IBOutlet UITextView *textView ;
@property (nonatomic,retain) IBOutlet UISwitch *imageSwitch ;
@property (nonatomic,retain) IBOutlet UISwitch *messageSwitch ;
@property (nonatomic,retain) IBOutlet UISwitch *linkSwitch ;

- (IBAction)segmentedControlValueChanged:(id)sender ;
- (IBAction)takePhotoButtonClicked:(id)sender ;
- (IBAction)selectPhotoButtonClicked:(id)sender ;
- (IBAction)loginButtonClicked:(id)sender ;
- (IBAction)logoutButtonClicked:(id)sender ;
- (IBAction)postButtonClicked:(id)sender ;

- (void)appendToLog:(NSString *)message ;

@end
