//
//  CubeNode.h
//  Cube Patterns 3
//
//  Created by Anton Holmberg on 2012-12-14.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import "GLKitPlusPlus.h"

@interface CubeNode : GPNode

+ (GLKBaseEffect *)sharedEffect;

- (id)initWithTextureNamed:(NSString *)textureName;

@end