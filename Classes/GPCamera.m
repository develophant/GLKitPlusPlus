//
//  GLCamera.m
//  GLKit++
//
//  Created by Anton Holmberg on 2012-12-14.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import "GPCamera.h"

@implementation GPCamera

- (id)init {
    if(self = [super init]) {
        self.invertScale = YES;
    }
    return self;
}

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

- (float)zoom {
    return self.s;
}

- (void)setZoom:(float)zoom {
    self.s = zoom;
}

- (GLKVector3)unprojectTouch:(UITouch *)touch forNode:(GPNode *)node z:(float)z {
    NSAssert([touch.view isKindOfClass:[GLKView class]], @"The camera can only unproject touches in the main GLKView");
    
    CGPoint point = [touch locationInView:touch.view];
    GLKVector3 windowCoord = GLKVector3Make(point.x,320 - point.y, z);
    
    //CGPoint viewOrigin = [touch.view convertPoint:CGPointZero toView:touch.view.window];
    //NSLog(@"point: %@", NSStringFromCGPoint(point));
    int viewport[] = {
        (int)0,
        (int)0,
        (int)touch.view.bounds.size.width,
        (int)touch.view.bounds.size.height
    };
    bool result;
    
    GLKVector3 unprojected = GLKMathUnproject(windowCoord,
                                              node.modelViewMatrix,
                                              self.projectionMatrix,
                                              &viewport[0], &result);
    
    if(!result) {
        NSLog(@"GLKMathUnproject didn't succeed");
    }
    
    return unprojected;
}

@end
