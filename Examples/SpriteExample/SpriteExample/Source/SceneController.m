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
@property (strong, nonatomic) GPSprite *airplane;

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
    
    glEnable(GL_CULL_FACE);
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
    
    GPSprite *trees = [GPSprite spriteWithImageNamed:@"trees"];
    trees.wrapTextureHorizontally = YES;
    trees.textureFrame = CGRectMake(0, 0, 4 * trees.imageSize.width, trees.imageSize.height);
    trees.width = 4 * trees.imageSize.width;
    trees.position = GLKVector3Make(0.5 * trees.width - viewSize.width/2, -26, 0);
    [self.scene addChild:trees];
    
    GPSprite *smiley = [GPSprite spriteWithImageNamed:@"smiley"];
    smiley.size = CGSizeMake(smiley.size.width * 0.5, smiley.size.height * 0.5);
    smiley.y = -viewSize.height/2 + smiley.height / 2 + 5;
    [self.scene addChild:smiley];
    
    [smiley animateWithDuration:0.8 options:GPAnimationRepeat animations:^{
        smiley.rz = -2*M_PI;
    }];
    
    [mountains animateWithDuration:viewSize.width * 0.01 options:GPAnimationRepeat animations:^{
        mountains.x -= mountains.width/2;
    }];
    
    [trees animateWithDuration:viewSize.width * 0.0023 options:GPAnimationRepeat animations:^{
        trees.x -= trees.width/4;
    }];
    
    [sun animateWithDuration:10 options:GPAnimationRepeat updates:^(float f) {
        // Move the sun in an oval
        sun.x = 190 * cos(-(f + 0.5)*2*M_PI);
        sun.y = - 40 + 120 * sin(-(f + 0.5)*2*M_PI);
        
        // p is 1 when the sun is at its highest, and goes down to -1 during the night.
        float p = sin(-(f + 0.5)*2*M_PI);
        
        background.color = GLKVector3Make(0.6 + 0.4 * p, 0.6 + 0.4 * p, 0.6 + 0.4 * p);
        GLKVector3 lightColor = GLKVector3Make(0.7 + 0.3 * p, 0.7 + 0.3 * p, 0.8 + 0.2 * p);
        self.airplane.color = mountains.color = trees.color = smiley.color = lightColor;
        sun.color = GLKVector3Make(1, 0.75 + 0.25 * p, 0.75 + 0.25 * p);
    }];
    
    [self createAndAnimateAirplane];
    
    // Setup updates
    self.preferredFramesPerSecond = 60;
}

- (void)createAndAnimateAirplane {
    
    self.airplane = [GPSprite spriteWithImageNamed:@"airplane"];
    self.airplane.y = 84;
    [self.scene insertChild:self.airplane atIndex:2];
    
    GLKVector3 startPos = self.airplane.position;
    [self.airplane animateWithDuration:4 options:GPAnimationRepeat updates:^(float f) {
        self.airplane.y = startPos.y + 40 * sin(f * 4 * M_PI);
        self.airplane.rz = 0.2 * sin((f + 0.125) * 4 * M_PI);
        self.airplane.x = -15 * sin(f * 2 * M_PI);
    }];
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


#pragma mark - Inherited update method

- (void)update {
    [[GPScheduler defaultScheduler] update:self];
}

#pragma mark - Interface orientation

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return UIInterfaceOrientationIsLandscape(toInterfaceOrientation);
}

#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if([self.airplane touchIsOnTop:[touches anyObject]]) {
        [self.airplane stopAllAnimations];
        self.airplane.userInteractionEnabled = NO;
        [self.airplane animateWithDuration:2 options:GPAnimationBeginFromCurrentState | GPAnimationEaseIn animations:^{
            self.airplane.y -= 220;
            self.airplane.rz = -0.45 * M_PI;
        }completion:^(BOOL finished) {
            [self.scene removeChild:self.airplane];
            self.airplane = nil;
            [self createAndAnimateAirplane];
        }];
    }
}

@end
