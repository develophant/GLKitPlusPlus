//
//  GLCamera.h
//  GLKit++
//
//  Created by Anton Holmberg on 2012-12-14.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>
#import "GPNode.h"

// The default viewing direction of the camera is negative z-axis.
@interface GPCamera : GPNode

@property GLKMatrix4 projectionMatrix;
@property float zoom;

+ (GPCamera *)cameraWithCenteredOthoProjectionForView:(UIView *)view;
- (GLKVector3)unprojectUIKitPoint:(CGPoint)p forNode:(GPNode *)node z:(float)z viewSize:(CGSize)viewSize;
- (GLKVector3)unprojectUIKitPoint:(CGPoint)p forNode:(GPNode *)node z:(float)z viewSize:(CGSize)viewSize result:(bool *)result;

@end