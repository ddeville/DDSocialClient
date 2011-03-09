//
//  NSData+Base64Encode.m
//  SocialNetworkClient
//
//  Created by Damien DeVille on 2/19/11.
//  Copyright 2011 Snappy Code. All rights reserved.
//

#import "NSData+Base64Encode.h"

static char base64EncodingTable[64] =
{
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
	'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
	'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/'
} ;

@implementation NSData (Base64Encode)

- (NSString *)base64EncodeWithLength:(NSUInteger)length
{
	NSData *data = self ;
	
	unsigned long ixtext ;
	unsigned long dataLength ;
	long remaining ;
	unsigned char input[3] ;
	unsigned char output[4] ;
	short i ;
	short charsonline = 0 ;
	short ctcopy ;
	const unsigned char *rawData ;
	NSMutableString *result ;
	
	dataLength = [data length] ;
	if (dataLength < 1)
		return @"" ;
	result = [NSMutableString stringWithCapacity: dataLength] ;
	rawData = [data bytes] ;
	ixtext = 0 ;
	
	while (true)
	{
		remaining = dataLength - ixtext ;
		if (remaining <= 0)
			break ;
		for (i = 0 ; i < 3 ; i++)
		{
			unsigned long ix = ixtext + i ;
			if (ix < dataLength)
				input[i] = rawData[ix] ;
			else
				input[i] = 0 ;
		}
		output[0] = (input[0] & 0xFC) >> 2 ;
		output[1] = ((input[0] & 0x03) << 4) | ((input[1] & 0xF0) >> 4) ;
		output[2] = ((input[1] & 0x0F) << 2) | ((input[2] & 0xC0) >> 6) ;
		output[3] = input[2] & 0x3F ;
		ctcopy = 4 ;
		switch (remaining)
		{
			case 1: 
				ctcopy = 2 ;
				break ;
			case 2:
				ctcopy = 3 ;
				break ;
		}
		
		for (i = 0 ; i < ctcopy ; i++)
			[result appendString: [NSString stringWithFormat: @"%c", base64EncodingTable[output[i]]]] ;
		
		for (i = ctcopy ; i < 4 ; i++)
			[result appendString: @"="] ;
		
		ixtext += 3 ;
		charsonline += 4 ;
		
		if ((length > 0) && (charsonline >= length))
			charsonline = 0 ;
	}
	return result ;
}

@end
