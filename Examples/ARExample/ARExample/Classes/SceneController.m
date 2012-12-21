//
//  GLViewController.m
//  SpriteExample
//
//  Created by Anton Holmberg on 2012-12-17.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import "SceneController.h"
#import <CoreMotion/CoreMotion.h>

@interface SceneController () {
    CGPoint _lastDragPoints[2];
    GLKVector3 _spinSpeed;
}

@property GPNode *scene;
@property CMMotionManager *motionManager;

@end

@implementation SceneController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.preferredFramesPerSecond = 60;
    
    self.view = [[GLKView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    [(GLKView *)self.view setDrawableMultisample:GLKViewDrawableMultisample4X];
    [(GLKView *)self.view setDrawableDepthFormat:GLKViewDrawableDepthFormat24];
    [(GLKView *)self.view setContext:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]];
    [EAGLContext setCurrentContext:[(GLKView *)self.view context]];
    
    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    
    self.scene = [[GPNode alloc] init];
    self.scene.camera = [[GPCamera alloc] init];
    
    GPSprite *floor = [GPSprite spriteWithImageNamed:@"grid"];
    floor.y = -5;
    floor.rx = -M_PI/2;
    floor.wrapTextureHorizontally = YES;
    floor.wrapTextureVertically = YES;
    floor.textureFrame = CGRectMake(0, 0, 100 * floor.imageSize.width, 100 * floor.imageSize.height);
    floor.size = CGSizeMake(100,100);
    [self.scene addChild:floor];
    
    [self.scene.camera animateWithDuration:8 animations:^{
        self.scene.camera.ry += 2 * M_PI;
    }];
    
    
	self.motionManager = [[CMMotionManager alloc] init];
	self.motionManager.showsDeviceMovementDisplay = YES;
	self.motionManager.deviceMotionUpdateInterval = 1.0/self.preferredFramesPerSecond;
	[self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
    
    [self addObserver:self forKeyPath:@"view.bounds" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    // Delete the scene
    self.scene = nil;
    
    // Tear down OpenGL
    if ([EAGLContext currentContext] == [(GLKView *)self.view context]) {
        [EAGLContext setCurrentContext:nil];
    }
    [(GLKView *)self.view setContext:nil];
}


#pragma mark - Key value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"view.bounds"]) {
        self.scene.camera.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(50.0f),
                                                                       self.view.bounds.size.width/self.view.bounds.size.height,
                                                                       0.1f, 1000.0f);
    }
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.scene draw];
}

#pragma mark - Inherited update method

- (void)update {
    [[GPScheduler defaultScheduler] update:self];
    [self updateCameraOrientation];
}

- (void)updateCameraOrientation {
    CMRotationMatrix r = self.motionManager.deviceMotion.attitude.rotationMatrix;
    GLKMatrix4 rotationMatrix = GLKMatrix4Make(r.m11, r.m12, r.m13, 0,
                                               r.m21, r.m22, r.m23, 0,
                                               r.m31, r.m32, r.m33, 0,
                                               0, 0, 0, 1);
    // The motion managers rotation matrix is defined with the z-axis upwards.
    // We rotate it -90 degrees around the x-axis to move make it match our coordinate system
    // where the z-axis is horizontally aligned.
    rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(-M_PI/2, 1, 0, 0), rotationMatrix);
    [self.scene.camera resetStoredRotation];
    [self.scene.camera setStoredRotationMatrix:rotationMatrix];
    
    self.scene.camera.rotation = GLKVector3Add(self.scene.camera.rotation, _spinSpeed);
    _spinSpeed = GLKVector3MultiplyScalar(_spinSpeed, 0.9);
    if(GLKVector3Length(_spinSpeed) > 0) {
        self.scene.camera.rx *= 0.9;
        self.scene.camera.rz *= 0.9;
    }
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint p = [[touches anyObject] locationInView:self.view];
    _lastDragPoints[0] = p;
    _lastDragPoints[1] = p;
    _spinSpeed = GLKVector3Make(0, 0, 0);
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint p = [[touches anyObject] locationInView:self.view];
    _lastDragPoints[1] = _lastDragPoints[0];
    _lastDragPoints[0] = p;
    GLKVector3 rotationDelta = GLKVector3Make(0.006 * (_lastDragPoints[0].y - _lastDragPoints[1].y),
                                              0.006 * (_lastDragPoints[0].x - _lastDragPoints[1].x),
                                              0);
    rotationDelta = GLKMatrix4MultiplyVector3(self.scene.camera.storedRotationMatrix, rotationDelta);
    self.scene.camera.rotation = GLKVector3Add(self.scene.camera.rotation, rotationDelta);
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    GLKVector3 newSpinSpeed = GLKVector3Make(0.006 * (_lastDragPoints[0].y - _lastDragPoints[1].y),
                                              0.006 * (_lastDragPoints[0].x - _lastDragPoints[1].x),
                                              0);
    newSpinSpeed = GLKMatrix4MultiplyVector3(self.scene.camera.storedRotationMatrix, newSpinSpeed);
    _spinSpeed = newSpinSpeed;
    
}

@end