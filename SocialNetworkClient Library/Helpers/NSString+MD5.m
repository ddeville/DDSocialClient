//
//  NSString+MD5.m
//  SocialNetworkClient
//
//  Created by Damien DeVille on 8/9/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import "NSString+MD5.h"
#import <CommonCrypto/CommonDigest.h>

@implementation NSString(MD5)

- (NSString *)MD5Hash
{
	const char *string = [self UTF8String] ;
	
	unsigned char result[CC_MD5_DIGEST_LENGTH] ;
	
	CC_MD5(string, strlen(string), result) ;
	
	return [NSString stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
			result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],
			result[8], result[9], result[10], result[11], result[12], result[13], result[14], result[15]
			] ;
}

@end