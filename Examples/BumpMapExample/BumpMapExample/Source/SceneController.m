//
//  SceneController.m
//  BumpMapExample
//
//  Created by Anton Holmberg on 2012-12-22.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import "SceneController.h"
#import "CubeNode.h"
#import "SphereNode.h"

#define CLAMP(x, a, b) MAX(a, MIN(b, x))

@interface SceneController () {
    CGPoint _lastDragPoints[2];
    GLKVector3 _spinVelocity;
}

@property GPNode *scene;
@property SphereNode *sphere;
@property GPSprite *background;

@end

@implementation SceneController
#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.preferredFramesPerSecond = 60;
    
    self.view = [[GLKView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    [(GLKView *)self.view setContext:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]];
    [EAGLContext setCurrentContext:[(GLKView *)self.view context]];
    
    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    
    self.scene = [[GPNode alloc] init];
    self.scene.camera = [[GPCamera alloc] init];
    self.scene.camera.z = 10;
    
    self.sphere = [[SphereNode alloc] initWithResolutionX:50 resolutionY:30 radius:3];
    self.sphere.invertXYRotationOrder = YES;
    
    [self.scene addChild:self.sphere];
    
    NSString *imagePath = [[NSBundle mainBundle] pathForResource:@"background" ofType:@"jpg"];
    self.background = [GPSprite spriteWithImage:[UIImage imageWithContentsOfFile:imagePath]];
    self.background.size = CGSizeMake(320, 568);
    self.background.camera = [GPCamera cameraWithCenteredOthoProjectionForView:self.view];
    
    [self addObserver:self forKeyPath:@"view.bounds" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];
}

#pragma mark - Key value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"view.bounds"]) {
        self.scene.camera.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(60.0f),
                                                                       self.view.bounds.size.width/self.view.bounds.size.height,
                                                                       0.1f, 1000.0f);
        self.background.camera = [GPCamera cameraWithCenteredOthoProjectionForView:self.view];
    }
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    // Delete the scene
    self.scene = nil;
    self.sphere = nil;
    
    // Tear down OpenGL
    if ([EAGLContext currentContext] == [(GLKView *)self.view context]) {
        [EAGLContext setCurrentContext:nil];
    }
    [(GLKView *)self.view setContext:nil];
}
#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    [self.background draw];
    [self.scene draw];
}


#pragma mark - Inherited update method

- (void)update {
    [[GPScheduler defaultScheduler] update:self];
    
    self.sphere.rotation = GLKVector3Add(self.sphere.rotation, _spinVelocity);
    self.sphere.rx = CLAMP(self.sphere.rx, -M_PI/3, M_PI/3);
    _spinVelocity = GLKVector3Make(0.9 * _spinVelocity.x, 0.98 * _spinVelocity.y, 0);
}

#pragma mark - Touches

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    _spinVelocity = GLKVector3Make(0, 0, 0);
    _lastDragPoints[0] = _lastDragPoints[1] = [[touches anyObject] locationInView:self.view];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint p2 = [touch locationInView:self.view];
    CGPoint p1 = [touch previousLocationInView:self.view];
    self.sphere.rotation = GLKVector3Add(self.sphere.rotation, GLKVector3Make(0.008f * (p2.y - p1.y), 0.008f * (p2.x - p1.x), 0));
    _lastDragPoints[0] = p2;
    _lastDragPoints[1] = p1;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    CGPoint p2 = _lastDragPoints[0];
    CGPoint p1 = _lastDragPoints[1];
    if(sqrtf((p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y)) > 3)
        _spinVelocity = GLKVector3Make(0.004f * (p2.y - p1.y), 0.008f * (p2.x - p1.x), 0);
    
}
@end