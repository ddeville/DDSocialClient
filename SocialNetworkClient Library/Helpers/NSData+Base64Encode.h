//
//  NSData+Base64Encode.h
//  SocialNetworkClient
//
//  Created by Damien DeVille on 2/19/11.
//  Copyright 2011 Snappy Code. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (Base64Encode)

- (NSString *)base64EncodeWithLength:(NSUInteger)length ;

@end
