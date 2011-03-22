//
//  DDiPhoneViewController.h
//  SocialNetworkClient
//
//  Created by Damien DeVille on 03/03/2010.
//  Copyright Damien DeVille 2010. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DDSocialClient.h"

@class DDFacebookClient ;
@class DDTwitterClient ;
@class DDFlickrClient ;
@class DDLinkedInClient ;
@class DDFoursquareClient ;

@interface DDiPhoneViewController : UIViewController <DDSocialClientDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
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
	DDFoursquareClient *foursquareClient ;
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
