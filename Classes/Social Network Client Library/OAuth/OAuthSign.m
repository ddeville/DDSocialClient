//
//  OAuthSign.m
//  DDSocialNetworkClient
//
//  Created by Damien DeVille on 8/5/10.
//  Copyright 2010 Damien DeVille. All rights reserved.
//

#import "OAuthSign.h"

#define COMMON_DIGEST_FOR_OPENSSL
#import <CommonCrypto/CommonDigest.h>
#include <CommonCrypto/CommonHMAC.h>

#define MD5(data, len, md)										CC_MD5(data, len, md)
#define SHA1(data, len, md)										CC_SHA1(data, len, md)
#define HMAC(evp_md, key, key_len, data, data_len, md, md_len)	CCHmac(evp_md, key, key_len, data, data_len, md)

#define MALLOC_CHECK_ASSIGN(rhs,size,fail) do { void* tmp = malloc( size ); if ( tmp == (void*) 0 ) return fail; rhs = tmp; } while (0)
#define STRDUP_CHECK_ASSIGN(rhs,str,fail) do { char* tmp = strdup( str ); if ( tmp == (char*) 0 ) return fail; rhs = tmp; } while (0)
#define PERCENT_ENCODE_CHECK_ASSIGN(rhs,str,fail) do { char* tmp = percent_encode( str ); if ( tmp == (char*) 0 ) return fail; rhs = tmp; } while (0)

#define max(a,b) ((a)>(b)?(a):(b))

static char* percent_encode( char* str ) ;
static int compare( const void* v1, const void* v2 ) ;
static void url_decode( char* to, char* from ) ;
static int from_hexit( char c ) ;
static void b64_encode( unsigned char* src, int len, char* dst ) ;

typedef struct
{
    char* name ;
    char* value ;
    char* encoded_name ;
    char* encoded_value ;
}
param ;






@interface OAuthSign (Private)

char* oauth_sign(char* consumer_key, char* consumer_key_secret, char* token, char* token_secret, char* method, char* url, char* callback, char* verifier, int paramc, char** paramv) ;

@end







@implementation OAuthSign

+ (NSString *)getOAuthSignatureForMethod:(NSString *)method URL:(NSString *)URL callback:(NSString *)callback consumerKey:(NSString *)consumerKey consumerKeySecret:(NSString *)consumerKeySecret token:(NSString *)token tokenSecret:(NSString *)tokenSecret verifier:(NSString *)verifier body:(NSDictionary *)body
{
	char *consumer_key ;
	char *consumer_key_secret ;
	char *token_c ;
	char *token_secret ;
	char *method_c ;
	char *URL_c ;
	char *callback_c ;
	char *verifier_c ;
	
	if (consumerKey)
		consumer_key = (char *)[consumerKey UTF8String] ;
	else
		consumer_key = "" ;
	
	if (consumerKeySecret)
		consumer_key_secret = (char *)[consumerKeySecret UTF8String] ;
	else
		consumer_key_secret = "" ;
	
	if (token)
		token_c = (char *)[token UTF8String] ;
	else
		token_c = "" ;
	
	if (tokenSecret)
		token_secret = (char *)[tokenSecret UTF8String] ;
	else
		token_secret = "" ;
	
	if (method)
		method_c = (char *)[method UTF8String] ;
	else
		method_c = "" ;
	
	if (URL)
		URL_c = (char *)[URL UTF8String] ;
	else
		URL_c = "" ;
	
	if (callback)
		callback_c = (char *)[callback UTF8String] ;
	else
		callback_c = "" ;
	
	if (verifier)
		verifier_c = (char *)[verifier UTF8String] ;
	else
		verifier_c = "" ;
	
	int bodyNumber = [body count] ;
	char *bodyArray[bodyNumber] ;
	if (bodyNumber)
	{
		int i = 0 ;
		for (NSString *key in body)
		{
			NSString *value ;
			if (value = [body objectForKey: key])
			{
				NSString *total = [NSString stringWithFormat: @"%@=%@", key, value] ;
				bodyArray[i] = strdup([total UTF8String]) ;
			}
			i++ ;
		}
	}
	
	char *sigResultC = oauth_sign(consumer_key, consumer_key_secret, token_c, token_secret, method_c, URL_c, callback_c, verifier_c, bodyNumber, &bodyArray[0]) ;
	
	NSString *sigResult = [NSString stringWithCString: sigResultC encoding: NSUTF8StringEncoding] ;
	free(sigResultC) ;
	
	return sigResult ;
}









/* oauth_sign.c - sign an OAuth request
 **
 ** Given a method, URL, consumer key & secret, and token & secret, this
 ** program returns the OAuth signature.  See:
 **   http://tools.ietf.org/html/rfc5849#section-3.1
 ** The signature is generated using HMAC-SHA1, as specified in:
 **   http://tools.ietf.org/html/rfc5849#section-3.4.2
 ** The protocol parameters are returned as an Authorization header
 ** value, as specified in:
 **   http://tools.ietf.org/html/rfc5849#section-3.5.1
 **
 ** Copyright � 2010 by Jef Poskanzer <jef@mail.acme.com>.
 ** All rights reserved.
 **
 ** Redistribution and use in source and binary forms, with or without
 ** modification, are permitted provided that the following conditions
 ** are met:
 ** 1. Redistributions of source code must retain the above copyright
 **    notice, this list of conditions and the following disclaimer.
 ** 2. Redistributions in binary form must reproduce the above copyright
 **    notice, this list of conditions and the following disclaimer in the
 **    documentation and/or other materials provided with the distribution.
 **
 ** THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ** ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 ** IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ** ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 ** FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 ** DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 ** OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ** HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 ** LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 ** OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 ** SUCH DAMAGE.
 **
 ** For commentary on this license please see http://acme.com/license.html
 */

char* oauth_sign(char* consumer_key, char* consumer_key_secret, char* token, char* token_secret, char* method, char* url, char* callback, char* verifier, int paramc, char** paramv)
{
	char* oauth_signature_method ;
	char oauth_timestamp[20] ;
	char oauth_nonce[20] ;
	char* oauth_version ;
	time_t now ;
	unsigned long nonce1, nonce2 ;
	char* qmark ;
	char* query_string ;
	int n_ampers ;
	int max_query_params, n_query_params ;
	param* query_params ;
	int max_post_params, n_post_params ;
	param* post_params ;
	int max_proto_params, n_proto_params ;
	param* proto_params ;
	int max_all_params, n_all_params ;
	param* all_params ;
	int i ;
	char* cp ;
	char* equal ;
	char* value ;
	char* amper ;
	char* base_url ;
	char* encoded_base_url ;
	char* qmark2 ;
	size_t params_string_len ;
	char* params_string ;
	char* encoded_params_string ;
	char* encoded_consumer_key_secret ;
	char* encoded_token_secret ;
	size_t base_string_len ;
	char* base_string ;
	size_t key_len ;
	char* key ;
	unsigned char hmac_block[SHA_DIGEST_LENGTH] ;
	char oauth_signature[SHA_DIGEST_LENGTH * 4/3 + 5] ;
	size_t authorization_len ;
	char* authorization ;
	
	/* Assign values to the rest of the required protocol params. */
	oauth_signature_method = "HMAC-SHA1" ;
	now = time( (time_t*) 0 ) ;
	(void) snprintf( oauth_timestamp, sizeof(oauth_timestamp), "%ld", (long) now ) ;
	srandomdev() ;
	nonce1 = (unsigned long) random() ;
	nonce2 = (unsigned long) random() ;
	(void) snprintf( oauth_nonce, sizeof(oauth_nonce), "%08lx%08lx", nonce1, nonce2 ) ;
	oauth_version = "1.0" ;

	/* Parse the URL's query-string params. */
	qmark = strchr( url, '?' ) ;
	if ( qmark == (char*) 0 )
	{
		STRDUP_CHECK_ASSIGN( query_string, "", (char*) 0 ) ;
		max_query_params = 1 ;		/* avoid malloc(0) */
	}
	else
	{
		STRDUP_CHECK_ASSIGN( query_string, qmark + 1, (char*) 0 ) ;
		n_ampers = 0 ;
		for ( i = 0; query_string[i] != '\0'; ++i )
			if ( query_string[i] == '&' )
				++n_ampers ;
		max_query_params = n_ampers + 1 ;
	}
	MALLOC_CHECK_ASSIGN( query_params, sizeof(param) * max_query_params, (char*) 0 ) ;
	n_query_params = 0 ;
	if ( qmark != (char*) 0 )
	{
		cp = query_string ;
		for (;;)
		{
			equal = strchr( cp, '=' ) ;
			amper = strchr( cp, '&' ) ;
			if ( equal == (char*) 0 || ( amper != (char*) 0 && amper < equal ) )
			{
				value = "" ;
			}
			else
			{
				*equal = '\0' ;
				value = equal + 1 ;
			}
			if ( amper != (char*) 0 )
				*amper = '\0' ;
			STRDUP_CHECK_ASSIGN( query_params[n_query_params].name, cp, (char*) 0 ) ;
			STRDUP_CHECK_ASSIGN( query_params[n_query_params].value, value, (char*) 0 ) ;
			url_decode( query_params[n_query_params].name, query_params[n_query_params].name ) ;
			url_decode( query_params[n_query_params].value, query_params[n_query_params].value ) ;
			++n_query_params ;
			if ( amper == (char*) 0 )
				break ;
			cp = amper + 1 ;
		}
	}
	
    /* Add in the optional POST params. */
	max_post_params = max( paramc, 1 ) ;		/* avoid malloc(0) */
	MALLOC_CHECK_ASSIGN( post_params, sizeof(param) * max_post_params, (char*) 0 ) ;
	n_post_params = 0 ;
	for ( n_post_params = 0; n_post_params < paramc; ++n_post_params )
	{
		STRDUP_CHECK_ASSIGN( post_params[n_post_params].name, paramv[n_post_params], (char*) 0 ) ;
		equal = strchr( post_params[n_post_params].name, '=' ) ;
		if ( equal == (char*) 0 )
			post_params[n_post_params].value = "" ;
		else
		{
			*equal = '\0' ;
			post_params[n_post_params].value = equal + 1 ;
		}
	}
	
	/* Make the protocol params. */
	max_proto_params = 9 ;
	MALLOC_CHECK_ASSIGN( proto_params, sizeof(param) * max_proto_params, (char*) 0 ) ;
	n_proto_params = 0 ;
	if ( strlen( consumer_key ) > 0 )
	{
		proto_params[n_proto_params].name = "oauth_consumer_key" ;
		proto_params[n_proto_params].value = consumer_key ;
		++n_proto_params ;
	}
	if ( strlen( token ) > 0 )
	{
		proto_params[n_proto_params].name = "oauth_token" ;
		proto_params[n_proto_params].value = token ;
		++n_proto_params ;
	}
	if ( strlen( callback ) > 0 )
	{
		proto_params[n_proto_params].name = "oauth_callback" ;
		proto_params[n_proto_params].value = callback ;
		++n_proto_params ;
	}
	if ( strlen( verifier ) > 0 )
	{
		proto_params[n_proto_params].name = "oauth_verifier" ;
		proto_params[n_proto_params].value = verifier ;
		++n_proto_params ;
	}
	proto_params[n_proto_params].name = "oauth_signature_method" ;
	proto_params[n_proto_params].value = oauth_signature_method ;
	++n_proto_params ;
	proto_params[n_proto_params].name = "oauth_timestamp" ;
	proto_params[n_proto_params].value = oauth_timestamp ;
	++n_proto_params ;
	proto_params[n_proto_params].name = "oauth_nonce" ;
	proto_params[n_proto_params].value = oauth_nonce ;
	++n_proto_params ;
	proto_params[n_proto_params].name = "oauth_version" ;
	proto_params[n_proto_params].value = oauth_version ;
	++n_proto_params ;
	
	/* Percent-encode and concatenate the parameter lists. */
	max_all_params = max_query_params + max_post_params + max_proto_params  ;
	MALLOC_CHECK_ASSIGN( all_params, sizeof(param) * max_all_params, (char*) 0 ) ;
	n_all_params = 0 ;
	for ( i = 0; i < n_query_params; ++i )
	{
		PERCENT_ENCODE_CHECK_ASSIGN( query_params[i].encoded_name, query_params[i].name, (char*) 0 ) ;
		PERCENT_ENCODE_CHECK_ASSIGN( query_params[i].encoded_value, query_params[i].value, (char*) 0 ) ;
		all_params[n_all_params] = query_params[i] ;
		++n_all_params ;
	}
	for ( i = 0; i < n_post_params; ++i )
	{
		PERCENT_ENCODE_CHECK_ASSIGN( post_params[i].encoded_name, post_params[i].name, (char*) 0 ) ;
		PERCENT_ENCODE_CHECK_ASSIGN( post_params[i].encoded_value, post_params[i].value, (char*) 0 ) ;
		all_params[n_all_params] = post_params[i] ;
		++n_all_params ;
	}
	for ( i = 0; i < n_proto_params; ++i )
	{
		PERCENT_ENCODE_CHECK_ASSIGN( proto_params[i].encoded_name, proto_params[i].name, (char*) 0 ) ;
		PERCENT_ENCODE_CHECK_ASSIGN( proto_params[i].encoded_value, proto_params[i].value, (char*) 0 ) ;
		all_params[n_all_params] = proto_params[i] ;
		++n_all_params ;
	}
	
	/* Sort the combined & encoded parameters. */
	qsort( all_params, n_all_params, sizeof(param), compare ) ;
	
	/* Construct the signature base string.  First get the base URL. */
	STRDUP_CHECK_ASSIGN( base_url, url, (char*) 0 ) ;
	qmark2 = strchr( base_url, '?' ) ;
	if ( qmark2 != (char*) 0 )
		*qmark2 = '\0' ;
	PERCENT_ENCODE_CHECK_ASSIGN( encoded_base_url, base_url, (char*) 0 ) ;
	
	/* Next make the parameters string.
	 **
	 ** There's a weirdness with the spec here.  According to RFC5849
	 ** sections 3.4.1.3.2 and 3.4.1.1, we should first concatenate the
	 ** encoded parameters together using "=" and "&", then percent-encode
	 ** the whole string.  However according to Twitter's implementation
	 ** guide at http://dev.twitter.com/pages/auth we should concatenate
	 ** the encoded parameters using "%3D" and "%26", which are the
	 ** percent-encoded versions of "=" and "&", and then *not*
	 ** percent-encode the whole string.  The difference is that
	 ** if we use the RFC's method, then anything that got percent-encoded
	 ** in the parameters gets percent-encoded a second time, resulting
	 ** in constructs like "%25xx" instead of "%xx".  We currently implement
	 ** the RFC's version, with the double-encoded percents, but
	 ** may switch to the other if there are interoperability problems.
	 */
	params_string_len = 0 ;
	for ( i = 0; i < n_all_params; ++i )
		params_string_len += 3 + strlen( all_params[i].encoded_name ) + 3 + strlen( all_params[i].encoded_value ) ;
	MALLOC_CHECK_ASSIGN( params_string, params_string_len + 1, (char*) 0 ) ;
	params_string[0] = '\0' ;
	for ( i = 0; i < n_all_params; ++i )
	{
		if ( i != 0 )
			(void) strcat( params_string, "&" ) ;
		(void) strcat( params_string, all_params[i].encoded_name ) ;
		(void) strcat( params_string, "=" ) ;
		(void) strcat( params_string, all_params[i].encoded_value ) ;
	}
	PERCENT_ENCODE_CHECK_ASSIGN( encoded_params_string, params_string, (char*) 0 ) ;
	
	/* Put together all the parts of the base string. */
	base_string_len = strlen( method ) + 1 + strlen( encoded_base_url ) + 1 + strlen( encoded_params_string ) ;
	MALLOC_CHECK_ASSIGN( base_string, base_string_len + 1, (char*) 0 ) ;
	(void) sprintf( base_string, "%s&%s&%s", method, encoded_base_url, encoded_params_string ) ;
	
	/* Calculate the signature. */
	PERCENT_ENCODE_CHECK_ASSIGN( encoded_consumer_key_secret, consumer_key_secret, (char*) 0 ) ;
	PERCENT_ENCODE_CHECK_ASSIGN( encoded_token_secret, token_secret, (char*) 0 ) ;
	key_len = strlen( encoded_consumer_key_secret ) + 1 + strlen( encoded_token_secret ) ;
	MALLOC_CHECK_ASSIGN( key, key_len + 1 , (char*) 0 ) ;
	(void) sprintf( key, "%s&%s", encoded_consumer_key_secret, encoded_token_secret ) ;
	//(void) HMAC( EVP_sha1(), key, strlen( key ), base_string, strlen( base_string ), hmac_block, (unsigned int*) 0 ) ;	// for Apple we need the following
	(void) HMAC( kCCHmacAlgSHA1, key, strlen( key ), base_string, strlen( base_string ), hmac_block, (unsigned int*) 0 ) ;
	b64_encode( hmac_block, SHA_DIGEST_LENGTH, oauth_signature ) ;
	
	/* Add the signature to the request too. */
	proto_params[n_proto_params].name = "oauth_signature" ;
	proto_params[n_proto_params].value = oauth_signature ;
	PERCENT_ENCODE_CHECK_ASSIGN( proto_params[n_proto_params].encoded_name, proto_params[n_proto_params].name, (char*) 0 ) ;
	PERCENT_ENCODE_CHECK_ASSIGN( proto_params[n_proto_params].encoded_value, proto_params[n_proto_params].value, (char*) 0 ) ;
	all_params[n_all_params] = proto_params[n_proto_params] ;
	++n_proto_params ;
	++n_all_params ;
	
	/* Generate the Authorization header value. */
	authorization_len = 6 ;
	for ( i = 0; i < n_proto_params; ++i )
		authorization_len += strlen( proto_params[i].encoded_name ) + 2 + strlen( proto_params[i].encoded_value ) + 3 ;
	MALLOC_CHECK_ASSIGN( authorization, authorization_len + 1 , (char*) 0 ) ;
	(void) strcpy( authorization, "OAuth " ) ;
	for ( i = 0; i < n_proto_params; ++i )
	{
		if ( i > 0 )
			(void) strcat( authorization, ", " ) ;
		(void) strcat( authorization, proto_params[i].encoded_name ) ;
		(void) strcat( authorization, "=\"" ) ;
		(void) strcat( authorization, proto_params[i].encoded_value ) ;
		(void) strcat( authorization, "\"" ) ;
	}
	
	/* Free everything except authorization. */
	free( query_string ) ;
	for ( i = 0; i < n_query_params; ++i )
	{
		free( query_params[i].name ) ;
		free( query_params[i].value ) ;
	}
	for ( i = 0; i < n_post_params; ++i )
		free( post_params[i].name ) ;
	for ( i = 0; i < n_all_params; ++i )
	{
		free( all_params[i].encoded_name ) ;
		free( all_params[i].encoded_value ) ;
	}
	free( query_params ) ;
	free( post_params ) ;
	free( proto_params ) ;
	free( all_params ) ;
	free( base_url ) ;
	free( encoded_base_url ) ;
	free( params_string ) ;
	free( encoded_params_string ) ;
	free( encoded_consumer_key_secret ) ;
	free( encoded_token_secret ) ;
	free( base_string ) ;
	free( key ) ;
	
	return authorization ;
}







static char* percent_encode( char* str )
{
	int max_len ;
	char* new_str ;
	char* cp ;
	char* new_cp ;
	char* ok = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~" ;
	char to_hexit[] = "0123456789ABCDEF" ;
	
	max_len = strlen( str ) * 3 ;
	MALLOC_CHECK_ASSIGN( new_str, max_len + 1, (char*) 0 ) ;
	for ( cp = str, new_cp = new_str; *cp != '\0'; ++cp )
	{
		if ( strchr( ok, *cp ) != (char*) 0 )
			*new_cp++ = *cp ;
		else
	    {
			*new_cp++ = '%' ;
			*new_cp++ = to_hexit[ ( (*cp) >> 4 ) & 0xf ] ;
			*new_cp++ = to_hexit[ (*cp) & 0xf ] ;
	    }
	}
	*new_cp = '\0' ;
	return new_str ;
}






static int compare( const void* v1, const void* v2 )
{
	const param* p1 = (const param*) v1 ;
	const param* p2 = (const param*) v2 ;
	int r = strcmp( p1->encoded_name, p2->encoded_name ) ;
	if ( r == 0 )
		r = strcmp( p1->encoded_value, p2->encoded_value ) ;
	return r ;
}





// Copies and decodes a string.  It's ok for from and to to be the same string
static void url_decode( char* to, char* from )
{
	for ( ; *from != '\0'; ++to, ++from )
	{
		if ( from[0] == '%' && isxdigit( from[1] ) && isxdigit( from[2] ) )
		{
			*to = from_hexit( from[1] ) * 16 + from_hexit( from[2] ) ;
			from += 2 ;
		}
		else if ( *from == '+' )
			*to = ' ' ;
		else
			*to = *from ;
	}
	*to = '\0' ;
}





static int from_hexit( char c )
{
	if ( c >= '0' && c <= '9' )
		return c - '0' ;
	if ( c >= 'a' && c <= 'f' )
		return c - 'a' + 10 ;
	if ( c >= 'A' && c <= 'F' )
		return c - 'A' + 10 ;
	return 0 ;	/* shouldn't happen, we're guarded by isxdigit() */
}






/* Base-64 encoding.  This encodes binary data as printable ASCII characters.
 ** Three 8-bit binary bytes are turned into four 6-bit values, like so:
 **
 **   [11111111]  [22222222]  [33333333]
 **
 **   [111111] [112222] [222233] [333333]
 **
 ** Then the 6-bit values are represented using the characters "A-Za-z0-9+/".
 */

static char b64_encode_table[64] =
{
	'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H',  /* 0-7 */
	'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',  /* 8-15 */
	'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X',  /* 16-23 */
	'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',  /* 24-31 */
	'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n',  /* 32-39 */
	'o', 'p', 'q', 'r', 's', 't', 'u', 'v',  /* 40-47 */
	'w', 'x', 'y', 'z', '0', '1', '2', '3',  /* 48-55 */
	'4', '5', '6', '7', '8', '9', '+', '/'   /* 56-63 */
} ;





static int b64_decode_table[256] =
{
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* 00-0F */
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* 10-1F */
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,62,-1,-1,-1,63,  /* 20-2F */
	52,53,54,55,56,57,58,59,60,61,-1,-1,-1,-1,-1,-1,  /* 30-3F */
	-1, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9,10,11,12,13,14,  /* 40-4F */
	15,16,17,18,19,20,21,22,23,24,25,-1,-1,-1,-1,-1,  /* 50-5F */
	-1,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,  /* 60-6F */
	41,42,43,44,45,46,47,48,49,50,51,-1,-1,-1,-1,-1,  /* 70-7F */
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* 80-8F */
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* 90-9F */
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* A0-AF */
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* B0-BF */
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* C0-CF */
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* D0-DF */
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,  /* E0-EF */
	-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1,-1   /* F0-FF */
} ;






/* Do base-64 encoding on a hunk of bytes.  Base-64 encoding takes up
 ** 4/3 the space of the original, plus up to 4 bytes for end-padding.
 */
static void b64_encode( unsigned char* src, int len, char* dst )
{
	int src_idx, dst_idx, phase ;
	char c ;
	
	dst_idx = 0 ;
	phase = 0 ;
	for ( src_idx = 0; src_idx < len; ++src_idx )
	{
		switch ( phase )
		{
			case 0:
				c = b64_encode_table[src[src_idx] >> 2] ;
				dst[dst_idx++] = c ;
				c = b64_encode_table[( src[src_idx] & 0x3 ) << 4] ;
				dst[dst_idx++] = c ;
				++phase ;
				break ;
			case 1:
				dst[dst_idx - 1] = b64_encode_table[b64_decode_table[(int) ((unsigned char) dst[dst_idx - 1])] | ( src[src_idx] >> 4 ) ] ;
				c = b64_encode_table[( src[src_idx] & 0xf ) << 2] ;
				dst[dst_idx++] = c ;
				++phase ;
				break ;
			case 2:
				dst[dst_idx - 1] = b64_encode_table[b64_decode_table[(int) ((unsigned char) dst[dst_idx - 1])] | ( src[src_idx] >> 6 ) ] ;
				c = b64_encode_table[src[src_idx] & 0x3f] ;
				dst[dst_idx++] = c ;
				phase = 0 ;
				break ;
		}
	}
	/* Pad with ='s. */
	while ( phase++ < 3 )
		dst[dst_idx++] = '=' ;
	/* And terminate. */
	dst[dst_idx++] = '\0' ;
}



@end
