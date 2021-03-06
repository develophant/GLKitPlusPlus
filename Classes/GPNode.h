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
    GPAnimationEaseInOut = 1<<5,
    GPAnimationBeginFromCurrentState = 1<<6
};
typedef enum GPAnimationOptions GPAnimationOptions;

typedef NSUInteger GPAnimationOptionsMask;

typedef void(^GPNodeAnimationsBlock)();
typedef void(^GPNodeUpdatesBlock)(float f);
typedef void(^GPNodeCompletionBlock)(BOOL finished);
typedef float(^GPNodeEasingCurve)(float f);

#define GPLERP(a, b, f) (a + f * (b - a))

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
@property BOOL userInteractionEnabled;

@property (readonly) GLKMatrix4 modelViewMatrix;
@property (readonly) GLKMatrix4 translationMatrix;

@property (readwrite) GLKMatrix4 storedRotationMatrix;
@property (readonly) GLKVector3 globalScale;

+ (GPNode *)node;

- (void)addChild:(GPNode *)node;
- (void)insertChild:(GPNode *)node atIndex:(NSUInteger)index;
- (void)removeChild:(GPNode *)node;
- (void)removeChildAtIndex:(NSUInteger)index;
- (NSUInteger)indexOfChild:(GPNode *)node;

// Store
- (void)storeCurrentRotation;
- (void)resetStoredRotation;

- (void)draw;

// --- Touch handling ---
- (GPNode *)touchedNodeOfUIKitPoint:(CGPoint)p viewSize:(CGSize)viewSize;
- (GLKVector3)closestIntersectionOfUIKitPoint:(CGPoint)p
                                     viewSize:(CGSize)viewSize;

GLKVector3 firstIntersectionOfRayWithTriangles(GLKVector3 rayStartPoint,
                                               GLKVector3 rayDirection,
                                               GLKVector3 *triangles,
                                               int triangleCount);

- (GLKVector3)convertPoint:(GLKVector3)p fromNode:(GPNode *)node;

// This method should be overriden by subclasses to enable touch intersection detection
@property (readonly) int triangleCount;
- (void)fillTriangles:(GLKVector3 *)triangles;



// Animation management
- (void)finishAllAnimations;
- (void)stopAllAnimations;
- (void)stopAnimationForKey:(NSString *)animationKey;
- (void)finishAnimationForKey:(NSString *)animationKey;
- (BOOL)hasAnimationRunningForKey:(NSString *)animationKey;

// Methods that add support for custom animations
- (GPNode *)copyWithSameProperties;
- (void)applyPropertiesOfNode:(GPNode *)node;
- (void)lerpUnequalPropertiesFromNode:(GPNode *)fromNode toNode:(GPNode *)toNode fraction:(float)f;
- (BOOL)propertiesAreEqualToNode:(GPNode *)node;

// Animations block based animation methods without key

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

// Animation block based animation methods with key

- (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(GPNodeAnimationsBlock)animations
                        key:(NSString *)animationKey;

- (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion
                        key:(NSString *)animationKey;

- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                 animations:(GPNodeAnimationsBlock)animations
                        key:(NSString *)animationKey;

- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion
                        key:(NSString *)animationKey;

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(NSUInteger)options
                 animations:(GPNodeAnimationsBlock)animations
                        key:(NSString *)animationKey;

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(GPAnimationOptionsMask)options
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion
                        key:(NSString *)animationKey;

// Updates block based animation methods without key
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

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurv
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion;

// Update block based animation methods with key
- (void)animateWithDuration:(NSTimeInterval)duration
                    updates:(GPNodeUpdatesBlock)updates
                        key:(NSString *)animationKey;

- (void)animateWithDuration:(NSTimeInterval)duration
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion
                        key:(NSString *)animationKey;

- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
                        key:(NSString *)animationKey;

- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion
                        key:(NSString *)animationKey;

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
                        key:(NSString *)animationKey;

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurv
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion
                        key:(NSString *)animationKey;
@end
