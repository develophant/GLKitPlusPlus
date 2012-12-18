//
//  GLViewController.m
//  SpriteExample
//
//  Created by Anton Holmberg on 2012-12-17.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import "SceneController.h"

@interface SceneController ()

@property GPNode *scene;
@property GPNode *touchNode;

@end

@implementation SceneController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup OpenGL
    self.view = [[GLKView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.height, 320)];
    [(GLKView *)self.view setContext:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]];
    [EAGLContext setCurrentContext:[(GLKView *)self.view context]];
    
    // Create the scene
    self.scene = [[GPNode alloc] init];
    self.scene.camera = [GPCamera cameraWithCenteredOthoProjectionForView:self.view];
    self.scene.camera.zoom = 1;
    
    CGSize viewSize = self.view.bounds.size;
    
    // Create sprites
    GPSprite *background = [GPSprite spriteWithImageNamed:@"background"];
    background.size = self.view.bounds.size;
    [self.scene addChild:background];
    
    GPSprite *sun = [GPSprite spriteWithImageNamed:@"sun"];
    [self.scene addChild:sun];
    
    GPSprite *mountains = [GPSprite spriteWithImageNamed:@"mountains"];
    mountains.size = CGSizeMake(2 * viewSize.width, 190);
    mountains.position = GLKVector3Make(0.5 * viewSize.width, -viewSize.height/2 + mountains.height / 2, 0);
    mountains.textureFrame = CGRectMake(0, 0, 2 * mountains.imageSize.width, mountains.imageSize.height);
    mountains.wrapTextureHorizontally = YES;
    [self.scene addChild:mountains];
    
    GPSprite *smiley = [GPSprite spriteWithImageNamed:@"smiley"];
    smiley.size = CGSizeMake(smiley.size.width * 0.5, smiley.size.height * 0.5);
    smiley.y = -viewSize.height/2 + smiley.height / 2 - 2;
    smiley.s = 0.5;
    [self.scene addChild:smiley];
    
    GPSprite *airplane = [GPSprite spriteWithImageNamed:@"airplane"];
    airplane.y = 84;
    [self.scene addChild:airplane];
    
    // Animate sprites
    [smiley animateWithDuration:20 options:GPAnimationRepeat animations:^{
        smiley.y = 70;
        smiley.x = -70;
        smiley.rz = -2*M_PI;
        smiley.s = 2;
    }];
    
    [mountains animateWithDuration:viewSize.width * 0.004 options:GPAnimationRepeat animations:^{
        mountains.x -= viewSize.width;
    }];
    
    [sun animateWithDuration:10 options:GPAnimationRepeat updates:^(float f) {
        // Move the sun in an oval
        sun.x = 190 * cos(-(f + 0.5)*2*M_PI);
        sun.y = - 40 + 120 * sin(-(f + 0.5)*2*M_PI);
        
        // p is 1 when the sun is at its highest, and goes down to -1 during the night.
        float p = sin(-(f + 0.5)*2*M_PI);
        background.color = GLKVector3Make(0.6 + 0.4 * p, 0.6 + 0.4 * p, 0.6 + 0.4 * p);
        GLKVector3 objectColor = GLKVector3Make(0.7 + 0.3 * p, 0.7 + 0.3 * p, 0.8 + 0.2 * p);
        mountains.color = airplane.color = smiley.color = objectColor;
        sun.color = GLKVector3Make(1, 0.75 + 0.25 * p, 0.75 + 0.25 * p);
    }];
    
    GLKVector3 startPos = airplane.position;
    [airplane animateWithDuration:4 options:GPAnimationRepeat updates:^(float f) {
        airplane.y = startPos.y + 40 * sin(f * 4 * M_PI);
        airplane.rz = 0.2 * sin((f + 0.125) * 4 * M_PI);
        airplane.x = -15 * sin(f * 2 * M_PI);
    }];
    
    // Setup updates
    self.preferredFramesPerSecond = 60;
    self.delegate = self;
    
    self.touchNode = smiley;
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

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if([self.touchNode isTouchingNode:[touches anyObject]]) {
        NSLog(@"is touching node!");
    }
}

@end
