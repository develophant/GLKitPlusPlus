//
//  GLViewController.m
//  SpriteExample
//
//  Created by Anton Holmberg on 2012-12-17.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import "SceneController.h"

#define isPhone5 ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone && [UIScreen mainScreen].bounds.size.height == 568)

@interface SceneController ()

@property GPNode *scene;

@end

@implementation SceneController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup OpenGL
    self.view = [[GLKView alloc] initWithFrame:CGRectMake(0, 0, isPhone5 ? 568 : 480, 320)];
    [(GLKView *)self.view setContext:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]];
    [EAGLContext setCurrentContext:[(GLKView *)self.view context]];
    
    // Create the scene
    self.scene = [[GPNode alloc] init];
    self.scene.camera = [GPCamera cameraWithCenteredOthoProjectionForView:self.view];
    self.scene.camera.s = 1;
    
    CGSize viewSize = self.view.bounds.size;
    
    // Create sprites
    GPSprite *background = [GPSprite spriteWithImageNamed:@"background"];
    background.size = self.view.bounds.size;
    [self.scene addChild:background];
    
    GPSprite *mountains = [GPSprite spriteWithImageNamed:@"mountains"];
    mountains.size = CGSizeMake(2 * viewSize.width, 190);
    mountains.position = GLKVector3Make(0.5 * viewSize.width, -viewSize.height/2 + mountains.height / 2, 0);
    mountains.textureFrame = CGRectMake(0, 0, 2 * mountains.imageSize.width, mountains.textureFrame.size.height);
    mountains.wrapTextureHorizontally = YES;
    [self.scene addChild:mountains];
    
    GPSprite *smiley = [GPSprite spriteWithImageNamed:@"smiley"];
    smiley.size = CGSizeMake(smiley.size.width * 0.5, smiley.size.height * 0.5);
    smiley.y = -viewSize.height/2 + smiley.height / 2 - 2;
    [self.scene addChild:smiley];
    
    GPSprite *airplane = [GPSprite spriteWithImageNamed:@"airplane"];
    airplane.y = 84;
    [self.scene addChild:airplane];
    
    // Animate sprites
    [smiley animateRepeatedWithDuration:0.86 animations:^{
        smiley.rz = -2*M_PI;
    }];
    [mountains animateRepeatedWithDuration:viewSize.width * 0.004 animations:^{
        mountains.x -= viewSize.width;
    }];
    
    GLKVector3 startPos = airplane.position;
    [airplane animateRepeatedWithDuration:4 updates:^(float f) {
        airplane.y = startPos.y + 40 * sin(f * 4 * M_PI);
        airplane.rz = 0.2 * sin((f + 0.125) * 4 * M_PI);
        airplane.x = -15 * sin(f * 2 * M_PI);
    }];
    
    // Setup updates
    self.preferredFramesPerSecond = 60;
    self.delegate = self;
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

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(1,1,1,1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.scene draw];
}

#pragma mark - GLKViewControllerDelegate

- (void)glkViewControllerUpdate:(GLKViewController *)controller {
    [[GPScheduler defaultScheduler] update:self];
}

#pragma mark - Interface orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

@end
