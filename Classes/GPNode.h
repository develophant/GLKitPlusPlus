//
//  GLNode.h
//  GLKit++
//
//  Created by Anton Holmberg on 2012-12-14.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

enum GPAnimationOptions
{
    GPAnimationAutoReverse = 1<<0,
    GPAnimationRepeat = 1<<1,
    
    GPAnimationNoEase = 1<<2,
    GPAnimationEaseIn = 1<<3,
    GPAnimationEaseOut = 1<<4,
    GPAnimationEaseInOut = 1<<53
};
typedef enum GPAnimationOptions GPAnimationOptions;

typedef NSUInteger GPAnimationOptionsMask;

typedef void(^GPNodeAnimationsBlock)();
typedef void(^GPNodeUpdatesBlock)(float f);
typedef void(^GPNodeCompletionBlock)();
typedef float(^GPNodeEasingCurve)(float f);

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

@property BOOL hidden;

@property (nonatomic, weak) GPNode *parent;
@property (readonly) BOOL isAnimating;

@property (nonatomic, strong) GPCamera *camera;

@property BOOL invertXYRotationOrder;
@property BOOL invertScale;

@property (readonly) GLKMatrix4 modelViewMatrix;

+ (GPNode *)node;
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

- (BOOL)isTouchingNode:(UITouch *)touch;

// Animations block based animation methods
- (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(GPNodeAnimationsBlock)animations;

- (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion;

- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                 animations:(GPNodeAnimationsBlock)animations;

- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion;

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(NSUInteger)options
                 animations:(GPNodeAnimationsBlock)animations;

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(GPAnimationOptionsMask)options
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion;

// Updates block based animation methods
- (void)animateWithDuration:(NSTimeInterval)duration
                    updates:(GPNodeUpdatesBlock)updates;

- (void)animateWithDuration:(NSTimeInterval)duration
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion;


- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates;

- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion;

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates;

// Designated animation method
- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion;


@end
