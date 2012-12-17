//
//  GLSprite.h
//  Cube Patterns 3
//
//  Created by Anton Holmberg on 2012-12-16.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import "GPNode.h"

@interface GPSprite : GPNode

// Public interface
@property (readwrite) CGSize size;
@property (readwrite) float width;
@property (readwrite) float height;
@property (readwrite) CGRect frame;
@property (readwrite) GLKVector4 color; // multiply color
@property (readwrite) CGRect textureFrame;
@property CGSize imageSize;

- (id)initWithImage:(UIImage *)image;
+ (id)spriteWithImage:(UIImage *)image;
+ (id)spriteWithImageNamed:(NSString *)imageName;

@end

// Protected interface
@interface GPSprite (Protected)

@property BOOL attribsAreDirty;
@property (nonatomic, strong) GLKTextureInfo *textureInfo;

+ (GLKBaseEffect *)sharedEffect;

- (void)createVertexArray;
- (void)updateVertexAttributes;

@end