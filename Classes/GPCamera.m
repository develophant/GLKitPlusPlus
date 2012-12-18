//
//  GLCamera.m
//  GLKit++
//
//  Created by Anton Holmberg on 2012-12-14.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import "GPCamera.h"

@implementation GPCamera

+ (GPCamera *)cameraWithCenteredOthoProjectionForView:(UIView *)view {
    GPCamera *camera = [[GPCamera alloc] init];
    camera.z = 50;
    camera.projectionMatrix = GLKMatrix4MakeOrtho(-view.bounds.size.width/2,
                                                  view.bounds.size.width/2,
                                                  -view.bounds.size.height/2,
                                                  view.bounds.size.height/2,
                                                  0.1, 100);
    return camera;
}

@end
