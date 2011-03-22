//
//  DDFoursquareClient.h
//  SocialClient
//
//  Created by Damien DeVille on 3/22/11.
//  Copyright 2011 Snappy Code. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DDSocialClient.h"
#import "ASIHTTPRequest.h"

@class DDFoursquareClient ;

@protocol DDFoursquareClientDelegate <NSObject, DDSocialClientDelegate>

@end


@interface DDFoursquareClient : DDSocialClient
{
	
}

@property (nonatomic,assign) id <DDFoursquareClientDelegate> delegate ;

- (id)initWithDelegate:(id <DDFoursquareClientDelegate>)theDelegate ;

@end
