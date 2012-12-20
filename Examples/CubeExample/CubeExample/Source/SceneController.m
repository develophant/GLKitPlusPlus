//
//  GLViewController.m
//  SpriteExample
//
//  Created by Anton Holmberg on 2012-12-17.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import "SceneController.h"
#import "CubeNode.h"

@interface SceneController ()

@property GPNode *scene;
@property CubeNode *cube;

@end

@implementation SceneController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    self.preferredFramesPerSecond = 60;
    
    self.view = [[GLKView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    
    [(GLKView *)self.view setDrawableDepthFormat:GLKViewDrawableDepthFormat24];
    [(GLKView *)self.view setContext:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]];
    
    
    [EAGLContext setCurrentContext:[(GLKView *)self.view context]];
    
    glEnable(GL_CULL_FACE);
    glEnable(GL_DEPTH_TEST);
    
    self.scene = [[GPNode alloc] init];
    self.scene.camera = [[GPCamera alloc] init];
    self.scene.camera.z = 10;
    
    self.cube = [[CubeNode alloc] initWithTextureNamed:@"companion_cube"];
    [self.scene addChild:self.cube];
    
    CubeNode.sharedEffect.light0.enabled = YES;
    CubeNode.sharedEffect.light0.diffuseColor = GLKVector4Make(1, 1, 1, 1);
    CubeNode.sharedEffect.light0.ambientColor = GLKVector4Make(0.7, 0.7, 0.7, 1);
    
    // Mutliply the light position with the invert of the camera's model view matrix
    // because it allows you to specifiy the position in the scenes coordinate system.
    // This is also what each nodes in the scene does to its coordinates before rendering
    // (it's included in the model view matrix of the node).
    CubeNode.sharedEffect.light0.position = GLKMatrix4MultiplyVector4(GLKMatrix4Invert(self.scene.camera.modelViewMatrix, nil),
                                                                      GLKVector4Make(-3, 6, 6, 1));
    
    [self.cube animateWithDuration:8 options:GPAnimationRepeat animations:^{
        self.cube.rx += 2 * M_PI;
        self.cube.ry += 4 * M_PI;
    }];
    
    self.cube.position = GLKVector3Make(-0.5, -1, 0);
    [self.cube animateWithDuration:1 options:GPAnimationRepeat | GPAnimationAutoReverse animations:^{self.cube.x += 1;}];
    [self.cube animateWithDuration:2.3 options:GPAnimationRepeat | GPAnimationAutoReverse animations:^{self.cube.y += 2;}];
    [self addObserver:self forKeyPath:@"view.bounds" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionInitial context:NULL];
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    // Delete the scene
    self.scene = nil;
    self.cube = nil;
    
    // Tear down OpenGL
    if ([EAGLContext currentContext] == [(GLKView *)self.view context]) {
        [EAGLContext setCurrentContext:nil];
    }
    [(GLKView *)self.view setContext:nil];
}


#pragma mark - Key value observing

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if([keyPath isEqualToString:@"view.bounds"]) {
        self.scene.camera.projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(40.0f),
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
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if([self.cube touchIsOnTop:[touches anyObject]]) {
        [self.cube animateWithDuration:0.3 options:GPAnimationAutoReverse animations:^{
            self.cube.z -= 4;
        } key:@"touchScale"];
    }
}

@end