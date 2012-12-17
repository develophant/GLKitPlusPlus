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

@property GPNode *world;

@end

@implementation SceneController

#pragma mark - Life cycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view = [[GLKView alloc] initWithFrame:CGRectMake(0, 0, isPhone5 ? 568 : 480, 320)];
    [(GLKView *)self.view setContext:[[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2]];
    [EAGLContext setCurrentContext:[(GLKView *)self.view context]];
    
    CGSize viewSize = self.view.bounds.size;
    
    self.preferredFramesPerSecond = 60;
    
    self.world = [[GPNode alloc] init];
    self.world.camera = [GPCamera cameraWithCenteredOthoProjectionForView:self.view];
    
    GPSprite *background = [GPSprite spriteWithImageNamed:@"background512"];
    background.size = self.view.bounds.size;
    [self.world addChild:background];
    
    GPSprite *mountains = [GPSprite spriteWithImageNamed:@"mountains_square"];
    mountains.size = CGSizeMake(2 * viewSize.width, 190);
    mountains.position = GLKVector3Make(0.5 * viewSize.width, -viewSize.height/2 + mountains.height / 2, 0);
    mountains.textureFrame = CGRectMake(0, 0, 2 * mountains.imageSize.width, mountains.textureFrame.size.height);
    [self.world addChild:mountains];
    
    GPSprite *smiley = [GPSprite spriteWithImageNamed:@"smiley"];
    smiley.size = CGSizeMake(smiley.size.width * 0.5, smiley.size.height * 0.5);
    smiley.y = -viewSize.height/2 + smiley.height / 2 - 2;
    [self.world addChild:smiley];
    
    [smiley animateRepeatedWithDuration:0.86 animations:^{ smiley.rz = -2*M_PI;}];
    [mountains animateRepeatedWithDuration:viewSize.width * 0.004 animations:^{ mountains.x -= viewSize.width;}];
    
    GPSprite *airplane = [GPSprite spriteWithImageNamed:@"airplane"];
    airplane.position = GLKVector3Make(-15, 80, 0);
    [self.world addChild:airplane];
    
    
    GLKVector3 startPos = airplane.position;
    [airplane animateRepeatedWithDuration:4 updates:^(float f) {
        airplane.y = startPos.y + 40 * sin(2*f * 2 * M_PI);
        airplane.rz = 0.2 * sin((2*f + 0.25) * 2 * M_PI);
        airplane.x = startPos.x + 2 * -startPos.x * (0.5 - 0.5 * sin(f * 2 * M_PI));
    }];
    
    self.delegate = self;
}

- (void)viewDidUnload {
    [super viewDidUnload];
    
    self.world = nil;
    
    if ([EAGLContext currentContext] == [(GLKView *)self.view context]) {
        [EAGLContext setCurrentContext:nil];
    }
    [(GLKView *)self.view setContext:nil];
}

#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(1,1,1,1);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.world draw];
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
