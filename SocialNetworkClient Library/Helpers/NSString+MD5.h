//
//  NSString+MD5.h
//  SocialNetworkClient
//
//  Created by Damien DeVille on 8/9/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString(MD5)

+ (NSString *)MD5Hash:(NSString *)stringToHash ;

@end