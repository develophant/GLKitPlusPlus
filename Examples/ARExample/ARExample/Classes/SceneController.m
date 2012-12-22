//
//  GLViewController.m
//  SpriteExample
//
//  Created by Anton Holmberg on 2012-12-17.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import "SceneController.h"
#import <CoreMotion/CoreMotion.h>

@interface SceneController ()

@property GPNode *scene;
@property GPSprite *floor;
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
    self.scene.camera.y = 2;
    
    self.floor = [GPSprite spriteWithImageNamed:@"grid"];
    self.floor.rx = -M_PI/2;
    self.floor.wrapTextureHorizontally = YES;
    self.floor.wrapTextureVertically = YES;
    self.floor.textureFrame = CGRectMake(0, 0,
                                         100 * self.floor.imageSize.width,
                                         100 * self.floor.imageSize.height);
    self.floor.size = CGSizeMake(100,100);
    [self.scene addChild:self.floor];
    
	self.motionManager = [[CMMotionManager alloc] init];
	self.motionManager.showsDeviceMovementDisplay = YES;
	self.motionManager.deviceMotionUpdateInterval = 1.0/self.preferredFramesPerSecond;
	[self.motionManager startDeviceMotionUpdatesUsingReferenceFrame:CMAttitudeReferenceFrameXArbitraryCorrectedZVertical];
    
    [self addObserver:self forKeyPath:@"view.bounds" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOccured:)];
    [self.view addGestureRecognizer:tapRecognizer];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    // Delete the scene
    self.scene = nil;
    self.floor = nil;
    
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
    // We rotate it -90 degrees around the x-axis to make it match our coordinate system
    // where the z-axis is horizontal.
    rotationMatrix = GLKMatrix4Multiply(GLKMatrix4MakeRotation(-M_PI/2, 1, 0, 0), rotationMatrix);
    self.scene.camera.storedRotationMatrix = rotationMatrix;
}

#pragma mark - Touch handling

- (void)tapOccured:(UITapGestureRecognizer *)tapRecognizer {
    CGPoint p = [tapRecognizer locationInView:self.view];
    CGSize viewSize = self.view.bounds.size;
    
    GPNode *touchedNode = [self.scene touchedNodeOfUIKitPoint:p viewSize:viewSize];
    
    if(touchedNode == self.floor) {
        GLKVector3 intersection = [touchedNode closestIntersectionOfUIKitPoint:p viewSize:viewSize];
        GLKVector3 scenePos = [self.scene convertPoint:intersection fromNode:touchedNode];
        
        GLKVector3 newCameraPos = GLKVector3Make(scenePos.x, self.scene.camera.y, scenePos.z);
        float distance = GLKVector3Distance(self.scene.camera.position, newCameraPos);
        [self.scene.camera animateWithDuration:0.1 * distance options:GPAnimationBeginFromCurrentState | GPAnimationNoEase animations:^{
            self.scene.camera.position = newCameraPos;
        } key:@"cameraTapMove"];
    }
}

@end