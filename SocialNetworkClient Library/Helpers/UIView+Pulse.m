//
//  UIView+Pulse.m
//  SocialNetworkClient
//
//  Created by Damien DeVille on 7/12/10.
//  Copyright 2010 Snappy Code. All rights reserved.
//

#import "UIView+Pulse.h"


@interface UIView (Private)

- (void)pulseGrowAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context ;
- (void)pulseShrinkAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context ;

@end


@implementation UIView (Pulse)

- (void)pulse
{
	CGFloat angle = atan2(self.transform.b, self.transform.a) ;
	[self setTransform: CGAffineTransformConcat(CGAffineTransformMakeRotation(angle), CGAffineTransformMakeScale(0.5f, 0.5f))] ;
	[UIView beginAnimations: nil context: nil] ;
	[UIView setAnimationDuration: 0.3f] ;
	[UIView setAnimationDelegate: self] ;
	[UIView setAnimationDidStopSelector: @selector(pulseGrowAnimationDidStop:finished:context:)] ;
	[self setTransform: CGAffineTransformConcat(CGAffineTransformMakeRotation(angle), CGAffineTransformMakeScale(1.1f, 1.1f))] ;
	[UIView commitAnimations] ;
}

- (void)pulseGrowAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	[UIView beginAnimations: nil context: nil] ;
	[UIView setAnimationDuration: 0.2f] ;
	[UIView setAnimationDelegate: self] ;
	[UIView setAnimationDidStopSelector: @selector(pulseShrinkAnimationDidStop:finished:context:)] ;
	CGFloat angle = atan2(self.transform.b, self.transform.a) ;
	[self setTransform: CGAffineTransformConcat(CGAffineTransformMakeRotation(angle), CGAffineTransformMakeScale(0.9f, 0.9f))] ;
	[UIView commitAnimations] ;
}

- (void)pulseShrinkAnimationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
{
	[UIView beginAnimations: nil context: nil] ;
	[UIView setAnimationDuration: 0.2f] ;
	CGFloat angle = atan2(self.transform.b, self.transform.a) ;
	[self setTransform: CGAffineTransformConcat(CGAffineTransformMakeRotation(angle), CGAffineTransformMakeScale(1.0f, 1.0f))] ;
	[UIView commitAnimations] ;
}

@end
