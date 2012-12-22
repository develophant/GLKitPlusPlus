//
//  GLNode.m
//  GLKit++
//
//  Created by Anton Holmberg on 2012-12-14.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import "GPNode.h"
#import "GPCamera.h"
#import "GPScheduler.h"
#import <float.h>

#define GPNodeRepeatForever -1

#define GPNodeEasingCurveLinear ^(float f) {return f;}
#define GPNodeEasingCurveEaseInOut ^(float f) {return 0.5f - 0.5f * cosf(M_PI * f);}
#define GPNodeEasingCurveEaseIn ^(float f) {return f * f;}
#define GPNodeEasingCurveEaseOut ^(float f) {return 1 - (f - 1) * (f - 1);}

// GPNodeAnimator should only be used inside the GPNode class.
// It's used for internal animation management.
@interface GPNodeAnimator : NSObject

@property (nonatomic, strong) NSMutableArray *childAnimators;
@property (readonly) BOOL isAnimating;

- (void)runWithDuration:(NSTimeInterval)duration
            easingCurve:(GPNodeEasingCurve)easingCurve
            autoReverse:(BOOL)autoReverse
                  times:(NSInteger)times
           updatesBlock:(GPNodeUpdatesBlock)updatesBlock
        completionBlock:(GPNodeCompletionBlock)completionBlock;

- (void)finishAnimating;
- (void)stopAnimating;

+ (GPNodeUpdatesBlock)divideAnimationsBlock:(GPNodeAnimationsBlock)animations
                                   rootNode:(GPNode *)rootNode
                           affectedChildren:(NSMutableArray *)affectedChildren
                                childBlocks:(NSMutableArray *)childBlocks;

@end


@interface GPNode ()

@property (readonly) GLKMatrix4 rotationMatrix;
@property (nonatomic, strong) NSMutableArray *children;
@property BOOL modelViewMatrixIsDirty;
@property (nonatomic, strong) NSMutableDictionary *namedAnimators;
@property (nonatomic, strong) NSMutableArray *anonymousAnimators;

@property GLKMatrix4 storedScaleMatrix;
@property GLKMatrix4 storedTranslationMatrix;
@property BOOL hasStoredRotation;
@property BOOL hasStoredScale;
@property BOOL hasStoredTranslation;

@end

@implementation GPNode

@synthesize position = _position;
@synthesize rotation = _rotation;
@synthesize scale = _scale;
@synthesize modelViewMatrix = _modelViewMatrix;
@synthesize modelViewMatrixIsDirty = _modelViewMatrixIsDirty;
@synthesize camera = _camera;
@synthesize storedRotationMatrix = _storedRotationMatrix;

- (id)init {
    if(self = [super init]) {
        self.position = GLKVector3Make(0, 0, 0);
        self.rotation = GLKVector3Make(0, 0, 0);
        self.storedRotationMatrix = GLKMatrix4Identity;
        self.storedScaleMatrix = GLKMatrix4Identity;
        self.storedTranslationMatrix = GLKMatrix4Identity;
        self.scale = GLKVector3Make(1, 1, 1);
        self.children = [NSMutableArray array];
        self.modelViewMatrixIsDirty = YES;
        self.userInteractionEnabled = YES;
        
        self.namedAnimators = [NSMutableDictionary dictionary];
        self.anonymousAnimators = [NSMutableArray array];
    }
    return self;
}

+ (GPNode *)node {
    return [[[self class] alloc] init];
}

- (void)dealloc {
    [_camera removeObserver:self forKeyPath:@"modelViewMatrixIsDirty"];
}

- (BOOL)modelViewMatrixIsDirty {
    return _modelViewMatrixIsDirty;
}

- (void)setModelViewMatrixIsDirty:(BOOL)modelViewMatrixIsDirty {
    _modelViewMatrixIsDirty = modelViewMatrixIsDirty;
    
    if(_modelViewMatrixIsDirty) {
        for(GPNode *node in self.children)
            node.modelViewMatrixIsDirty = YES;
    }
}

#pragma mark - Getters / setters

- (void)setPosition:(GLKVector3)position {
    _position = position;
    self.modelViewMatrixIsDirty = YES;
}

- (GLKVector3)position {return _position;}

- (void)setRotation:(GLKVector3)rotation {
    _rotation = rotation;
    self.modelViewMatrixIsDirty = YES;
}

- (GLKVector3)rotation {return _rotation;};

- (void)setScale:(GLKVector3)scale {
    _scale = scale;
    self.modelViewMatrixIsDirty = YES;
}

- (GLKVector3)scale {return _scale;}

#pragma mark - Convenient getters / setters

// Position
- (void)setX:(float)x {_position.x = x;self.modelViewMatrixIsDirty = YES;}
- (float)x {return _position.x;}
- (void)setY:(float)y { _position.y = y;self.modelViewMatrixIsDirty = YES;}
- (float)y { return _position.y;}
- (void)setZ:(float)z {_position.z = z;self.modelViewMatrixIsDirty = YES;}
- (float)z {return _position.z;}

// Rotation
- (void)setRx:(float)rx {_rotation.x = rx;self.modelViewMatrixIsDirty = YES;}
- (float)rx {return _rotation.x;}
- (void)setRy:(float)ry { _rotation.y = ry;self.modelViewMatrixIsDirty = YES;}
- (float)ry { return _rotation.y; }
- (void)setRz:(float)rz {_rotation.z = rz;self.modelViewMatrixIsDirty = YES;}
- (float)rz {return _rotation.z;}

// Scale
- (void)setSx:(float)sx {_scale.x = sx;self.modelViewMatrixIsDirty = YES;}
- (float)sx {return _scale.x;}
- (void)setSy:(float)sy { _scale.y = sy;self.modelViewMatrixIsDirty = YES;}
- (float)sy { return _scale.y; }
- (void)setSz:(float)sz {_scale.z = sz;self.modelViewMatrixIsDirty = YES;}
- (float)sz {return _scale.z;}

- (void)setS:(float)s {
    _scale = GLKVector3Make(s, s, s);
    self.modelViewMatrixIsDirty = YES;
}

- (GLKVector3)globalScale {
    if(self.parent) {
        return GLKVector3Multiply(self.scale, self.parent.globalScale);
    }
    else return self.scale;
}

- (float)s {return (self.sx + self.sy + self.sz)/3;}

#pragma mark - Model View Matrix

- (GLKMatrix4)modelViewMatrix {
    if(self.modelViewMatrixIsDirty) {
        
        GLKMatrix4 localModelViewMatrix = GLKMatrix4Multiply(GLKMatrix4MakeTranslation(self.x, self.y, self.z),
                                                             GLKMatrix4Multiply(self.scaleMatrix, self.rotationMatrix));
        GLKMatrix4 rawModelViewMatrix = self.parent ? GLKMatrix4Multiply(self.parent.modelViewMatrix, localModelViewMatrix) : localModelViewMatrix;
        
        if([self class] != [GPCamera class])
            NSAssert(self.camera, @"The node must have a camera (may be inherited from the parent");
        
        // Only apply the camera transformation if the node has a camera that is not inherited from the parent
        _modelViewMatrix = _camera ? GLKMatrix4Multiply(GLKMatrix4Invert(_camera.modelViewMatrix, nil), rawModelViewMatrix) : rawModelViewMatrix;
        self.modelViewMatrixIsDirty = NO;
    }
    return _modelViewMatrix;
}

#pragma mark - Children Management

- (void)addChild:(GPNode *)node {
    [self.children addObject:node];
    node.parent = self;
}

- (void)insertChild:(GPNode *)node atIndex:(NSUInteger)index {
    node.parent = self;
    [self.children insertObject:node atIndex:index];
}

- (void)removeChild:(GPNode *)node {
    node.parent = nil;
    [self.children removeObject:node];
}

- (void)removeChildAtIndex:(NSUInteger)index {
    [[self.children objectAtIndex:index] setParent:nil];
    [self.children removeObjectAtIndex:index];
}

- (NSUInteger)indexOfChild:(GPNode *)node {
    return [self.children indexOfObject:node];
}

- (NSArray *)childrenInTree {
    NSMutableArray *childrenInTree = [NSMutableArray array];
    [self enumerateChildrenRecursively:^(GPNode *child) {
        [childrenInTree addObject:child];
    }];
    return childrenInTree;
}

- (GLKVector3)convertPoint:(GLKVector3)p fromNode:(GPNode *)node {
    GLKVector4 worldPoint = GLKMatrix4MultiplyVector4(node.modelViewMatrix, GLKVector4MakeWithVector3(p, 1));
    GLKVector4 localPoint = GLKMatrix4MultiplyVector4(GLKMatrix4Invert(self.modelViewMatrix, nil), worldPoint);
    return GLKVector3Make(localPoint.x, localPoint.y, localPoint.z);
}

#pragma mark - Camera

- (GPCamera *)camera {
    return _camera ? _camera : self.parent.camera;
}

- (void)setCamera:(GPCamera *)camera {
    [_camera removeObserver:self forKeyPath:@"modelViewMatrixIsDirty"];
    
    _camera = camera;
    [_camera addObserver:self forKeyPath:@"modelViewMatrixIsDirty" options:NSKeyValueObservingOptionNew context:nil];
    self.modelViewMatrixIsDirty = YES;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if(object == self.camera) {
        if(self.camera.modelViewMatrixIsDirty)
            self.modelViewMatrixIsDirty = YES;
    }
}

#pragma mark - Stored transformations

- (GLKMatrix4)rawRotationMatrix {
    GLKMatrix4 rotationMatrix = GLKMatrix4Identity;
    
    if(self.invertXYRotationOrder) {
        rotationMatrix = GLKMatrix4Rotate(rotationMatrix, self.rx, 1, 0, 0);
        rotationMatrix = GLKMatrix4Rotate(rotationMatrix, self.ry, 0, 1, 0);
        rotationMatrix = GLKMatrix4Rotate(rotationMatrix, self.rz, 0, 0, 1);
    }
    else {
        rotationMatrix = GLKMatrix4Rotate(rotationMatrix, self.ry, 0, 1, 0);
        rotationMatrix = GLKMatrix4Rotate(rotationMatrix, self.rx, 1, 0, 0);
        rotationMatrix = GLKMatrix4Rotate(rotationMatrix, self.rz, 0, 0, 1);
    }
    return rotationMatrix;
}

- (GLKMatrix4)translationMatrix {
    
    GLKMatrix4 tm = GLKMatrix4MakeTranslation(self.x, self.y, self.z);
    NSLog(@"return translation matrix: %@", NSStringFromGLKMatrix4(tm));
    
    return tm;
}

- (GLKMatrix4)rotationMatrix {
    if(self.hasStoredRotation)
        return GLKMatrix4Multiply(self.rawRotationMatrix, self.storedRotationMatrix);
    else return self.rawRotationMatrix;
}

- (GLKMatrix4)rawScaleMatrix {
    return GLKMatrix4MakeScale(self.invertScale ? 1/self.sx : self.sx,
                               self.invertScale ? 1/self.sy : self.sy,
                               self.invertScale ? 1/self.sz : self.sz);
}

- (GLKMatrix4)scaleMatrix {
    if(self.hasStoredScale)
        return GLKMatrix4Multiply(self.rawScaleMatrix, self.storedScaleMatrix);
    else return self.rawScaleMatrix;
}

- (void)storeCurrentRotation {
    self.storedRotationMatrix = GLKMatrix4Multiply(self.rawRotationMatrix, self.storedRotationMatrix);
    self.rotation = GLKVector3Make(0, 0, 0);
    self.hasStoredRotation = YES;
}

- (void)setStoredRotationMatrix:(GLKMatrix4)rotationMatrix {
    _storedRotationMatrix = rotationMatrix;
    self.hasStoredRotation = YES;
    self.modelViewMatrixIsDirty = YES;
}

- (GLKMatrix4)storedRotationMatrix {
    return _storedRotationMatrix;
}
/*
- (void)storeScale {
    self.storedScaleMatrix = GLKMatrix4Multiply(self.rawScaleMatrix, self.storedScaleMatrix);
    self.scale = GLKVector3Make(1, 1, 1);
    self.hasStoredScale = YES;
}*/

- (void)resetStoredRotation {
    self.storedRotationMatrix = GLKMatrix4Identity;
    self.modelViewMatrixIsDirty = YES;
    self.hasStoredRotation = NO;
}
/*
- (void)resetStoredScale {
    self.storedScaleMatrix = GLKMatrix4Identity;
    self.modelViewMatrixIsDirty = YES;
    self.hasStoredScale = NO;
}*/

- (void)draw {
    if(self.hidden) return;
    
    for(GPNode *child in self.children) {
        [child draw];
    }
}

#pragma mark - Triangles

- (void)fillTriangles:(GLKVector3 *)triangles {
    // Should be overriden by subclasses
}

- (int)triangleCount {
    // Should be overriden by subclasses
    return 0;
}

#pragma mark - Collision detection


- (GPNode *)touchedNodeOfUIKitPoint:(CGPoint)p viewSize:(CGSize)viewSize {
    
    GPNode *closestNode = nil;
    float minDistance = FLT_MAX;
    
    for(GPNode *node in [[self childrenInTree] arrayByAddingObject:self]) {
        int triangleCount = node.triangleCount;
        GLKVector3 triangles[3 * triangleCount];
        [node fillTriangles:triangles];
        
        GLKVector3 globalScale = node.globalScale;
        for(int i = 0; i < 3 * triangleCount; i++)
            triangles[i] = GLKVector3Multiply(triangles[i], globalScale);
        
        GLKVector3 nearPoint = [node.camera unprojectUIKitPoint:p forNode:node z:0 viewSize:viewSize];
        nearPoint = GLKVector3Multiply(nearPoint, globalScale);
        GLKVector3 farPoint = [node.camera unprojectUIKitPoint:p forNode:node z:1 viewSize:viewSize];
        farPoint = GLKVector3Multiply(farPoint, globalScale);
        GLKVector3 direction = GLKVector3Normalize(GLKVector3Subtract(farPoint, nearPoint));
        
        
        GLKVector3 intersection = firstIntersectionOfRayWithTriangles(nearPoint, direction, triangles, triangleCount);
        
        if(!GLKVector3AllEqualToScalar(intersection, 0)) {
            float distance = GLKVector3Distance(nearPoint, intersection);
            if(distance < minDistance) {
                minDistance = distance;
                closestNode = node;
            }
        }
    }
    return closestNode.userInteractionEnabled ? closestNode : nil;
}

- (GLKVector3)closestIntersectionOfUIKitPoint:(CGPoint)p
                                     viewSize:(CGSize)viewSize {
    
    GLKVector3 nearPoint = [self.camera unprojectUIKitPoint:p forNode:self z:0 viewSize:viewSize];
    GLKVector3 farPoint = [self.camera unprojectUIKitPoint:p forNode:self z:1 viewSize:viewSize];
    GLKVector3 direction = GLKVector3Normalize(GLKVector3Subtract(farPoint, nearPoint));
    
    int triangleCount = self.triangleCount;
    GLKVector3 triangles[3 * triangleCount];
    [self fillTriangles:triangles];
    return firstIntersectionOfRayWithTriangles(nearPoint, direction, triangles, triangleCount);
    
}

// Uses the algorithm described here
// http://gamedeveloperjourney.blogspot.se/2009/04/point-plane-collision-detection.html
GLKVector3 firstIntersectionOfRayWithTriangles(GLKVector3 rayStartPoint,
                                               GLKVector3 rayDirection,
                                               GLKVector3 *triangles,
                                               int triangleCount) {
    float minT = FLT_MAX;
    for(int i = 0; i < triangleCount; i++) {
        GLKVector3 *triangle = &triangles[3*i];
        
        GLKVector3 planeNormal = GLKVector3Normalize(GLKVector3CrossProduct(GLKVector3Subtract(triangle[1], triangle[0]),
                                                                            GLKVector3Subtract(triangle[2], triangle[1])));
        float d = -GLKVector3DotProduct(triangle[0], planeNormal);
        
        float divisor = GLKVector3DotProduct(planeNormal, rayDirection);
        if(fabs(divisor) < 0.0000001f) {
            // The triangle and ray are parallel
            continue;
        }
        
        float t = - (d + GLKVector3DotProduct(planeNormal, rayStartPoint)) / divisor;
        if(t < 0) {
            continue;
        }
        
        GLKVector3 intersection = GLKVector3Add(rayStartPoint, GLKVector3MultiplyScalar(rayDirection, t));
        
        GLKVector3 v[] =
        {
            GLKVector3Normalize(GLKVector3Subtract(intersection, triangle[0])),
            GLKVector3Normalize(GLKVector3Subtract(intersection, triangle[1])),
            GLKVector3Normalize(GLKVector3Subtract(intersection, triangle[2]))
        };
        
        // Angles around intersection should total 360 degrees (2 PI)
        float angleSum = acosf(GLKVector3DotProduct(v[0], v[1])) + acosf(GLKVector3DotProduct(v[1], v[2])) + acosf(GLKVector3DotProduct(v[2], v[0]));
        
        // taking abs(angleSum) makes the order of the triangle vertices unimportant (probably)
        if(fabs(fabs(angleSum) - (2 * M_PI)) < 0.001) {
            minT = MIN(minT, t);
        }
    }
    if(minT != FLT_MAX) {
        return GLKVector3Add(rayStartPoint, GLKVector3MultiplyScalar(rayDirection, minT));
    }
    else return GLKVector3Make(0, 0, 0);
}

#pragma mark - Properties copying/interpolation

// Provides a constructor which doesn't do anything.
// This allows the method copyWithSameProperties to create "cheap"
// copies of objects of subclasses even if they do all kinds of
// resource intense stuff in the default init constructor.
- (id)initShallow {
    if (self = [super init]) {
        
    }
    return self;
}

- (GPNode *)copyWithSameProperties {
    GPNode *node = [[[self class] alloc] initShallow];
    [node applyPropertiesOfNode:self];
    return node;
}

- (void)applyPropertiesOfNode:(GPNode *)node {
    self.position = node.position;
    self.rotation = node.rotation;
    self.scale = node.scale;
}

- (void)lerpUnequalPropertiesFromNode:(GPNode *)fromNode toNode:(GPNode *)toNode fraction:(float)f {
    if(fromNode.x != toNode.x) self.x = GPLERP(fromNode.x, toNode.x, f);
    if(fromNode.y != toNode.y) self.y = GPLERP(fromNode.y, toNode.y, f);
    if(fromNode.z != toNode.z) self.z = GPLERP(fromNode.z, toNode.z, f);
    
    if(fromNode.rx != toNode.rx) self.rx = GPLERP(fromNode.rx, toNode.rx, f);
    if(fromNode.ry != toNode.ry) self.ry = GPLERP(fromNode.ry, toNode.ry, f);
    if(fromNode.rz != toNode.rz) self.rz = GPLERP(fromNode.rz, toNode.rz, f);
    
    if(fromNode.sx != toNode.sx) self.sx = GPLERP(fromNode.sx, toNode.sx, f);
    if(fromNode.sy != toNode.sy) self.sy = GPLERP(fromNode.sy, toNode.sy, f);
    if(fromNode.sz != toNode.sz) self.sz = GPLERP(fromNode.sz, toNode.sz, f);
}

- (BOOL)propertiesAreEqualToNode:(GPNode *)node {
    return
    GLKVector3AllEqualToVector3(self.position, node.position) &&
    GLKVector3AllEqualToVector3(self.rotation, node.rotation) &&
    GLKVector3AllEqualToVector3(self.scale, node.scale);
}


#pragma mark - Recursive tree functions

typedef void(^ChildrenWorkBlock)(GPNode *node);

// Depth first visit
- (void)enumerateChildrenRecursively:(ChildrenWorkBlock)block {
    for(GPNode *child in self.children) {
        block(child);
        [child enumerateChildrenRecursively:block];
    }
}

#pragma mark - Animation management

- (BOOL)isAnimating {
    return self.namedAnimators.count > 0 || self.anonymousAnimators.count > 0;
}

- (BOOL)hasAnimationRunningForKey:(NSString *)animationKey {
    return [[self.namedAnimators objectForKey:animationKey] isAnimating];
}

- (void)finishAllAnimations {
    NSArray *oldAnonymousAnimations = [self.anonymousAnimators copy];
    [self.anonymousAnimators removeAllObjects];
    NSArray *oldNamedAnimators = [self.namedAnimators.allValues copy];
    [self.namedAnimators removeAllObjects];
    
    for(GPNodeAnimator *animator in oldAnonymousAnimations) {
        [animator finishAnimating];
    }
    
    for(GPNodeAnimator *namedAnimator in oldNamedAnimators) {
        [namedAnimator finishAnimating];
    }
}

- (void)stopAllAnimations {
    NSArray *oldAnonymousAnimations = [self.anonymousAnimators copy];
    [self.anonymousAnimators removeAllObjects];
    NSArray *oldNamedAnimators = [self.namedAnimators.allValues copy];
    [self.namedAnimators removeAllObjects];
    
    for(GPNodeAnimator *animator in oldAnonymousAnimations) {
        [animator stopAnimating];
    }
    
    for(GPNodeAnimator *namedAnimator in oldNamedAnimators) {
        [namedAnimator stopAnimating];
    }
}

- (void)finishAnimationForKey:(NSString *)animationKey {
    GPNodeAnimator *oldAnimator = [self.namedAnimators objectForKey:animationKey];
    [self.namedAnimators removeObjectForKey:animationKey];
    [oldAnimator finishAnimating];
}

- (void)stopAnimationForKey:(NSString *)animationKey {
    GPNodeAnimator *oldAnimator = [self.namedAnimators objectForKey:animationKey];
    [self.namedAnimators removeObjectForKey:animationKey];
    [oldAnimator stopAnimating];
}

- (void)finishAnonymousAnimator:(GPNodeAnimator *)animator {
    [self.anonymousAnimators removeObject:animator];
    [animator finishAnimating];
}

- (void)stopAnonymousAnimator:(GPNodeAnimator *)animator {
    [self.anonymousAnimators removeObject:animator];
    [animator stopAnimating];
}

- (GPNodeAnimator *)createAnimatorForKey:(NSString *)animationKey
                   beginFromCurrentState:(BOOL)beginFromCurrentState {
    
    GPNodeAnimator *animator = [[GPNodeAnimator alloc] init];
    
    if(animationKey) {
        if([self.namedAnimators objectForKey:animationKey]) {
            if(beginFromCurrentState) [self stopAnimationForKey:animationKey];
            else [self finishAnimationForKey:animationKey];
        }
        
        if([self.namedAnimators objectForKey:animationKey]) {
            NSLog(@"Failed to remove present animation for key when creating new animation for the key, most likely because the completion block of the present animation creates a new animation for the same key. ABORTING.");
            return nil;
        }
        [self.namedAnimators setObject:animator forKey:animationKey];
    }
    else {
        [self.anonymousAnimators addObject:animator];
    }
    return animator;
}

#pragma mark - Animation methods

- (GPNodeEasingCurve)easingCurveFromOptions:(GPAnimationOptionsMask)options {
    if(options & GPAnimationNoEase) return GPNodeEasingCurveLinear;
    else if(options & GPAnimationEaseIn) return GPNodeEasingCurveEaseIn;
    else if(options & GPAnimationEaseOut) return GPNodeEasingCurveEaseOut;
    else if(options & GPAnimationEaseInOut) return GPNodeEasingCurveEaseInOut;
    
    if(options & GPAnimationRepeat && !(options & GPAnimationAutoReverse))
        return GPNodeEasingCurveLinear;
    else return GPNodeEasingCurveEaseInOut;
}

#pragma mark - Animations block based animation method without key

- (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(GPNodeAnimationsBlock)animations
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:0
                   animations:animations
                   completion:nil
                          key:nil];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:0
                   animations:animations
                   completion:completion
                          key:nil];
}


- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                 animations:(GPNodeAnimationsBlock)animations
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:options
                   animations:animations
                   completion:nil
                          key:nil];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:options
                   animations:animations
                   completion:completion
                          key:nil];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(GPAnimationOptionsMask)options
                 animations:(GPNodeAnimationsBlock)animations
{
    [self animateWithDuration:duration
                  easingCurve:easingCurve
                      options:options
                   animations:animations
                   completion:nil
                          key:nil];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(GPAnimationOptionsMask)options
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion
{
    [self animateWithDuration:duration
                  easingCurve:easingCurve
                      options:options
                   animations:animations
                   completion:completion
                          key:nil];
}

#pragma mark - Animations block based animation method with key

- (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(GPNodeAnimationsBlock)animations
                        key:(NSString *)animationKey
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:0
                   animations:animations
                   completion:nil
                          key:animationKey];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion
                        key:(NSString *)animationKey
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:0
                   animations:animations
                   completion:completion
                          key:animationKey];
}


- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                 animations:(GPNodeAnimationsBlock)animations
                        key:(NSString *)animationKey
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:options
                   animations:animations
                   completion:nil
                          key:animationKey];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion
                        key:(NSString *)animationKey
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:options
                   animations:animations
                   completion:completion
                          key:animationKey];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(GPAnimationOptionsMask)options
                 animations:(GPNodeAnimationsBlock)animations
                        key:(NSString *)animationKey
{
    [self animateWithDuration:duration
                  easingCurve:easingCurve
                      options:options
                   animations:animations
                   completion:nil
                          key:animationKey];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(GPAnimationOptionsMask)options
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completion
                        key:(NSString *)animationKey
{
    [self animateWithDuration:duration
                  easingCurve:easingCurve ? easingCurve : [self easingCurveFromOptions:options]
                  autoReverse:options & GPAnimationAutoReverse
                        times:(options & GPAnimationRepeat) ? GPNodeRepeatForever : 1
        beginFromCurrentState:options & GPAnimationBeginFromCurrentState
                   animations:animations
                   completion:completion
                          key:animationKey];
}

#pragma mark - Updates block based animation methods without key

- (void)animateWithDuration:(NSTimeInterval)duration
                    updates:(GPNodeUpdatesBlock)updates
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:0
                      updates:updates
                   completion:nil
                          key:nil];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:0
                      updates:updates
                   completion:completion
                          key:nil];
}


- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:options
                      updates:updates
                   completion:nil
                          key:nil];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:options
                      updates:updates
                   completion:completion
                          key:nil];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
{
    [self animateWithDuration:duration
                  easingCurve:easingCurve
                      options:options
                      updates:updates
                   completion:nil
                          key:nil];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion
{
    [self animateWithDuration:duration
                  easingCurve:easingCurve
                      options:options
                      updates:updates
                   completion:completion
                          key:nil];
}
#pragma mark - Updates block based animation methods without key

- (void)animateWithDuration:(NSTimeInterval)duration
                    updates:(GPNodeUpdatesBlock)updates
                        key:(NSString *)animationKey
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:0
                      updates:updates
                   completion:nil
                          key:animationKey];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion
                        key:(NSString *)animationKey
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:0
                      updates:updates
                   completion:completion
                          key:animationKey];
}


- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
                        key:(NSString *)animationKey
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:options
                      updates:updates
                   completion:nil
                          key:animationKey];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion
                        key:(NSString *)animationKey
{
    [self animateWithDuration:duration
                  easingCurve:nil
                      options:options
                      updates:updates
                   completion:completion
                          key:animationKey];
}

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
                        key:(NSString *)animationKey
{
    [self animateWithDuration:duration
                  easingCurve:easingCurve
                      options:options
                      updates:updates
                   completion:nil
                          key:animationKey];
}
- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                    options:(GPAnimationOptionsMask)options
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completion
                        key:(NSString *)animationKey
{
    [self animateWithDuration:duration
                  easingCurve:easingCurve ? easingCurve : [self easingCurveFromOptions:options]
                  autoReverse:options & GPAnimationAutoReverse
                        times:(options & GPAnimationRepeat) ? GPNodeRepeatForever : 1
        beginFromCurrentState:options & GPAnimationBeginFromCurrentState
                      updates:updates
                   completion:completion
                          key:animationKey
                       parent:nil];
}

#pragma mark - Actual internal animation methods

- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                autoReverse:(BOOL)autoReverse
                      times:(NSInteger)times
      beginFromCurrentState:(BOOL)beginFromCurrentState
                    updates:(GPNodeUpdatesBlock)updates
                 completion:(GPNodeCompletionBlock)completionBlock
                        key:(NSString *)animationKey
                     parent:(GPNodeAnimator *)parent
{
    GPNodeAnimator *animator = [self createAnimatorForKey:animationKey
                                    beginFromCurrentState:beginFromCurrentState];
    if(!animator) return;
    
    if(parent)
        [parent.childAnimators addObject:animator];
    
    [animator runWithDuration:duration
                  easingCurve:easingCurve
                  autoReverse:autoReverse
                        times:times
                 updatesBlock:updates
              completionBlock:completionBlock];
}

// This is where the magic happens
- (void)animateWithDuration:(NSTimeInterval)duration
                easingCurve:(GPNodeEasingCurve)easingCurve
                autoReverse:(BOOL)autoReverse
                      times:(NSInteger)times
      beginFromCurrentState:(BOOL)beginFromCurrentState
                 animations:(GPNodeAnimationsBlock)animations
                 completion:(GPNodeCompletionBlock)completionBlock
                        key:(NSString *)animationKey {
    
    NSMutableArray *affectedChildren = [NSMutableArray array];
    NSMutableArray *childBlocks = [NSMutableArray array];
    
    // extract local updates, affected children and children updates block
    // by running the animations block only once
    // affectedChildren and childBlocks are filled by the method
    if(duration > 0) {
        
        GPNodeAnimator *animator = [self createAnimatorForKey:animationKey
                                        beginFromCurrentState:beginFromCurrentState];
        
        GPNodeUpdatesBlock localBlock = [GPNodeAnimator divideAnimationsBlock:animations
                                                                     rootNode:self
                                                             affectedChildren:affectedChildren
                                                                  childBlocks:childBlocks];
        if(!animator) return;
        
        [animator runWithDuration:duration
                      easingCurve:easingCurve
                      autoReverse:autoReverse
                            times:times
                     updatesBlock:localBlock
                  completionBlock:^(BOOL finished)
         {
             if(finished) {
                 if(animationKey) [self finishAnimationForKey:animationKey];
                 else [self finishAnonymousAnimator:animator];
             }
             else {
                 if(animationKey) [self stopAnimationForKey:animationKey];
                 else [self stopAnonymousAnimator:animator];
             }
             
             if(completionBlock)
                 completionBlock(finished);
         }];
        
        for(int i = 0; i < affectedChildren.count; i++) {
            [[affectedChildren objectAtIndex:i] animateWithDuration:duration
                                                        easingCurve:easingCurve
                                                        autoReverse:autoReverse
                                                              times:times
                                              beginFromCurrentState:NO
                                                            updates:[childBlocks objectAtIndex:i]
                                                         completion:nil
                                                                key:nil
                                                             parent:animator];
        }
    }
    else {
        
        GPNodeUpdatesBlock localBlock = [GPNodeAnimator divideAnimationsBlock:animations
                                                                     rootNode:self
                                                             affectedChildren:affectedChildren
                                                                  childBlocks:childBlocks];
        localBlock(autoReverse ? 0 : 1);
        for(GPNodeAnimationsBlock childBlock in childBlocks) {
            childBlock(autoReverse ? 0 : 1);
        }
        completionBlock(YES);
    }
}

@end


#pragma mark - GPNodeAnimator Implementation

@interface GPNodeAnimator ()

@property NSTimeInterval duration;
@property (nonatomic, strong) GPNodeEasingCurve easingCurve;
@property float normalizedLength;
@property NSInteger timesLeft;
@property float elapsedTime;

@property (nonatomic, strong) GPNodeUpdatesBlock updatesBlock;
@property (nonatomic, strong) GPNodeCompletionBlock completionBlock;

@end

@implementation GPNodeAnimator

- (id)init {
    if(self = [super init]) {
        self.childAnimators = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)runWithDuration:(NSTimeInterval)duration
            easingCurve:(GPNodeEasingCurve)easingCurve
            autoReverse:(BOOL)autoReverse
                  times:(NSInteger)times
           updatesBlock:(GPNodeUpdatesBlock)updatesBlock
        completionBlock:(GPNodeCompletionBlock)completionBlock {
    
    if(self.isAnimating) {
        [self finishAnimating];
    }
    
    self.updatesBlock = updatesBlock;
    self.completionBlock = completionBlock;
    
    self.elapsedTime = 0;
    self.duration = duration;
    self.easingCurve = easingCurve;
    
    self.normalizedLength = autoReverse ? 2 : 1;
    self.timesLeft = times;
    
    if(self.duration > 0) {
        [[GPScheduler defaultScheduler] scheduleUpdates:self];
    }
    else {
        [self finishAnimating];
    }
}

- (BOOL)isAnimating {
    return self.updatesBlock != nil;
}

- (void)update:(GLKViewController *)vc {
    self.elapsedTime += vc.timeSinceLastUpdate;
    
    float realDuration = self.duration * self.normalizedLength;
    if(self.elapsedTime < realDuration) {
        [self updateAnimation:self.elapsedTime/self.duration];
    }
    else {
        BOOL repeat = NO;
        if(self.timesLeft != GPNodeRepeatForever) {
            self.timesLeft--;
            if(self.timesLeft <= 0) {
                [self finishAnimating];
            }
            else {
                repeat = YES;
            }
        }
        else {
            repeat = YES;
        }
        
        if(repeat) {
            self.elapsedTime -= floorf(self.elapsedTime/realDuration) * realDuration;
            [self updateAnimation:self.elapsedTime/self.duration];
        }
    }
}

- (void)stopAnimating {
    for(GPNodeAnimator *childAnimator in self.childAnimators) {
        [childAnimator stopAnimating];
    }
    [self destroyAnimationAndFinish:NO];
}

- (void)finishAnimating {
    for(GPNodeAnimator *childAnimator in self.childAnimators) {
        [childAnimator finishAnimating];
    }
    [self destroyAnimationAndFinish:YES];
}

- (void)destroyAnimationAndFinish:(BOOL)finishAnimation {
    if(!self.isAnimating) return;
    
    if(self.duration > 0)
        [[GPScheduler defaultScheduler] unscheduleUpdates:self];
    
    if(finishAnimation) {
        [self updateAnimation:self.normalizedLength];
    }
    
    self.updatesBlock = nil;
    self.easingCurve = nil;
    self.duration = 0;
    self.elapsedTime = 0;
    
    // Assign the completion block to a local variable in case
    // The block makes this animator animate again.
    GPNodeCompletionBlock completionBlock = self.completionBlock;
    self.completionBlock = nil;
    
    if(completionBlock)
        completionBlock(finishAnimation);
}

- (void)updateAnimation:(float)f {
    float localF = self.easingCurve(f > 1 ? 2 - f : f);
    if(self.updatesBlock) {
        self.updatesBlock(localF);
    }
    else {
        NSLog(@"Node animator is animating without an updates block!");
    }
}

// extract local updates, affected children and children updates block
// by running the animations block only once
// affectedChildren and childBlocks are filled by the method
+ (GPNodeUpdatesBlock)divideAnimationsBlock:(GPNodeAnimationsBlock)animations
                                   rootNode:(GPNode *)rootNode
                           affectedChildren:(NSMutableArray *)affectedChildren
                                childBlocks:(NSMutableArray *)childBlocks
{
    NSArray *children = [rootNode childrenInTree];
    
    NSMutableArray *startChildren = [NSMutableArray arrayWithCapacity:children.count];
    for(GPNode *child in children)
        [startChildren addObject:[child copyWithSameProperties]];
    
    GPNode *startRootNode = [rootNode copyWithSameProperties];
    
    animations();
    
    NSMutableArray *endChildren = [NSMutableArray arrayWithCapacity:children.count];
    for(GPNode *child in children)
        [endChildren addObject:[child copyWithSameProperties]];
    
    GPNode *endRootNode = [rootNode copyWithSameProperties];
    
    for(int i = 0; i < children.count; i++) {
        GPNode *child = [children objectAtIndex:i];
        GPNode *startChild = [startChildren objectAtIndex:i];
        GPNode *endChild = [endChildren objectAtIndex:i];
        
        [child applyPropertiesOfNode:startChild];
        
        if(![startChild propertiesAreEqualToNode:endChild]) {
            [affectedChildren addObject:child];
            [childBlocks addObject:[^(float f) {
                [child lerpUnequalPropertiesFromNode:startChild toNode:endChild fraction:f];
            } copy]];
        }
    }
    
    [rootNode applyPropertiesOfNode:startRootNode];
    
    return [^(float f) {
        [rootNode lerpUnequalPropertiesFromNode:startRootNode toNode:endRootNode fraction:f];
    } copy];
}

@end