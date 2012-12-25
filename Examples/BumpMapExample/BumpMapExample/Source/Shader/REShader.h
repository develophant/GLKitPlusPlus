//
//  REShader.h
//  RenderEngine
//
//  Created by Anton Holmquist on 9/12/11.
//  Copyright 2011 Monterosa. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface REShader : NSObject {
    GLenum type;
    GLuint shader;
    
    NSString *string;
}

@property (nonatomic, readonly) GLuint shader;


- (id)initWithType:(GLenum)type string:(NSString*)string; // Designated
- (id)initWithType:(GLenum)type filename:(NSString*)filename;

@end
