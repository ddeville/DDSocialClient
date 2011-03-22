//
//  DDFoursquareClient.m
//  SocialClient
//
//  Created by Damien DeVille on 3/22/11.
//  Copyright 2011 Snappy Code. All rights reserved.
//

#import "DDFoursquareClient.h"

@implementation DDFoursquareClient

@dynamic delegate ;

- (id)initWithDelegate:(id <DDFoursquareClientDelegate>)theDelegate
{
	if ((self = [super initWithDelegate: theDelegate]))
	{
		[self setDelegate: theDelegate] ;
	}
	
	return self ;
}

@end
