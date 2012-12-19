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
    camera.projectionMatrix = GLKMatrix4MakeOrtho(-view.bounds.size.width/2,
                                                  view.bounds.size.width/2,
                                                  -view.bounds.size.height/2,
                                                  view.bounds.size.height/2,
                                                  0.1, 1000);
    camera.z = 500;
    return camera;
}

- (float)zoom {
    return self.s;
}

- (void)setZoom:(float)zoom {
    self.s = zoom;
}

- (GLKVector3)unprojectUIKitPoint:(CGPoint)p forNode:(GPNode *)node z:(float)z viewSize:(CGSize)viewSize {
    return [self unprojectUIKitPoint:p forNode:node z:z viewSize:viewSize result:nil];
}

- (GLKVector3)unprojectUIKitPoint:(CGPoint)p forNode:(GPNode *)node z:(float)z viewSize:(CGSize)viewSize result:(bool *)result {
    p.y = viewSize.height - p.y;
    
    int viewport[] = {
        0,
        0,
        (int)viewSize.width,
        (int)viewSize.height
    };
    
    return GLKMathUnproject(GLKVector3Make(p.x, p.y, z),
                            node.modelViewMatrix,
                            self.projectionMatrix,
                            &viewport[0], result);
}

@end
