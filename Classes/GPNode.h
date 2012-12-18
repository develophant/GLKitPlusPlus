//
//  GLNode.h
//  GLKit++
//
//  Created by Anton Holmberg on 2012-12-14.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

typedef void(^GPNodeAnimationsBlock)();
typedef void(^GPNodeUpdatesBlock)(float f);
typedef void(^GPNodeCompletionBlock)();
typedef float(^GPNodeEasingCurve)(float f);

#define GPNodeEasingCurveLinear ^(float f) {return f;}
#define GPNodeEasingCurveEaseInOut ^(float f) {return 0.5f - 0.5f * cosf(M_PI * f);}
#define GPNodeEasingCurveEaseIn ^(float f) {return f * f;}
#define GPNodeEasingCurveEaseOut ^(float f) {return 1 - (f - 1) * (f - 1);}

#define GPNodeIndefinitely -1

@class GPCamera;

@interface GPNode : NSObject {
    
}

@property GLKVector3 position;
@property GLKVector3 rotation;
@property GLKVector3 scale;

@property float x;
@property float y;
@property float z;

@property float rx;
@property float ry;
@property float rz;

@property float sx;
@property float sy;
@property float sz;
@property float s; // Average scale

@property (nonatomic, weak) GPNode *parent;
@property (readonly) BOOL isAnimating;

@property (nonatomic, strong) GPCamera *camera;
@property BOOL invertXYRotationOrder;

@property (readonly) GLKMatrix4 modelViewMatrix;

- (void)addChild:(GPNode *)node;
- (void)removeChild:(GPNode *)node;
- (NSArray *)childrenInTree;

- (void)storeRotation;
- (void)resetStoredRotation;
- (void)draw;

- (id)initShallow;

- (GPNode *)copyWithSameProperties;
- (void)applyPropertiesOfNode:(GPNode *)node;
- (void)lerpUnequalPropertiesFromNode:(GPNode *)fromNode toNode:(GPNode *)toNode fraction:(float)f;
- (BOOL)propertiesAreEqualToNode:(GPNode *)node;

- (void)finishAnimation;

// Animations block based animation methods
- (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(GPNodeAnimationsBlock)animations;

- (void)animateRepeatedWithDuration:(NSTimeInterval)duration
                         animations:(GPNodeAnimationsBlock)animations;

- (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion;

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                 animations:(GPNodeAnimationsBlock)animations;

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion;

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                autoReverse:(BOOL)autoReverse
                      times:(NSInteger)times
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion;

// Updates block based animation methods
- (void)animateWithDuration:(NSTimeInterval)duration
                    updates:(GPNodeUpdatesBlock)updates;

- (void)animateRepeatedWithDuration:(NSTimeInterval)duration
                            updates:(GPNodeUpdatesBlock)updates;

- (void)animateWithDuration:(NSTimeInterval)duration
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion;

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    updates:(GPNodeUpdatesBlock)updates;

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion;

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                autoReverse:(BOOL)autoReverse
                      times:(NSInteger)times
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion;


@end
