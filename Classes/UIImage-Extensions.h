	//
	//  UIImage-Extensions.h
	//
	//  Created by Hardy Macia on 7/1/09.
	//  Copyright 2009 Catamount Software. All rights reserved.
	//
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIImage (CS_Extensions)
// rotate UIImage to any angle
-(UIImage*)rotate:(UIImageOrientation)orient;

// rotate and scale image from iphone camera
-(UIImage*)rotateAndScaleFromCameraWithMaxSize:(CGFloat)maxSize;

// scale this image to a given maximum width and height
-(UIImage*)scaleWithMaxSize:(CGFloat)maxSize;
-(UIImage*)scaleWithMaxSize:(CGFloat)maxSize
					quality:(CGInterpolationQuality)quality;

@end;