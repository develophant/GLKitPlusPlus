//
//  CubeNode.m
//  Cube Patterns 3
//
//  Created by Anton Holmberg on 2012-12-14.
//  Copyright (c) 2012 Anton Holmberg. All rights reserved.
//

#import "CubeNode.h"


typedef struct {
    GLKVector3 Position;
    GLKVector2 TexCoord;
    GLKVector3 Normal;
} VertexAttribs;

const VertexAttribs Vertices[] = {
    // Front
    {{0.5, -0.5, 0.5},  {1, 0}, {0, 0, 1}},
    {{0.5, 0.5, 0.5}, {1, 1}, {0, 0, 1}},
    {{-0.5, 0.5, 0.5}, {0, 1}, {0, 0, 1}},
    {{-0.5, -0.5, 0.5}, {0, 0}, {0, 0, 1}},
    // Back
    {{0.5, 0.5, -0.5}, {0, 1}, {0, 0, -1}},
    {{-0.5, -0.5, -0.5}, {1, 0}, {0, 0, -1}},
    {{0.5, -0.5, -0.5}, {0, 0}, {0, 0, -1}},
    {{-0.5, 0.5, -0.5}, {1, 1}, {0, 0, -1}},
    // Left
    {{-0.5, -0.5, 0.5}, {1, 0}, {-1, 0, 0}},
    {{-0.5, 0.5, 0.5}, {1, 1}, {-1, 0, 0}},
    {{-0.5, 0.5, -0.5}, {0, 1}, {-1, 0, 0}},
    {{-0.5, -0.5, -0.5}, {0, 0}, {-1, 0, 0}},
    // Right
    {{0.5, -0.5, -0.5}, {1, 0}, {1, 0, 0}},
    {{0.5, 0.5, -0.5}, {1, 1}, {1, 0, 0}},
    {{0.5, 0.5, 0.5}, {0, 1}, {1, 0, 0}},
    {{0.5, -0.5, 0.5}, {0, 0}, {1, 0, 0}},
    // Top
    {{0.5, 0.5, 0.5}, {1, 0}, {0, 1, 0}},
    {{0.5, 0.5, -0.5}, {1, 1}, {0, 1, 0}},
    {{-0.5, 0.5, -0.5}, {0, 1}, {0, 1, 0}},
    {{-0.5, 0.5, 0.5}, {0, 0}, {0, 1, 0}},
    // Bottom
    {{0.5, -0.5, -0.5}, {1, 0}, {0, -1, 0}},
    {{0.5, -0.5, 0.5}, {1, 1}, {0, -1, 0}},
    {{-0.5, -0.5, 0.5}, {0, 1}, {0, -1, 0}},
    {{-0.5, -0.5, -0.5}, {0, 0}, {0, -1, 0}}
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 6, 5,
    4, 5, 7,
    // Left
    8, 9, 10,
    10, 11, 8,
    // Right
    12, 13, 14,
    14, 15, 12,
    // Top
    16, 17, 18,
    18, 19, 16,
    // Bottom
    20, 21, 22,
    22, 23, 20
};

@interface CubeNode ()

@property GLuint vertexBuffer;
@property GLuint indexBuffer;
@property GLuint vertexArray;
@property GLKTextureInfo *textureInfo;

@end

@implementation CubeNode

#pragma mark - Class variables

static GLKBaseEffect *SHARED_EFFECT;

+ (GLKBaseEffect *)sharedEffect {
    if(!SHARED_EFFECT) {
        
        SHARED_EFFECT = [[GLKBaseEffect alloc] init];
        SHARED_EFFECT.texture2d0.enabled = true;
    }
    return SHARED_EFFECT;
}

static BOOL SHARED_VERTEX_ARRAY_IS_CREATED = NO;
static GLuint SHARED_VERTEX_ARRAY;
static GLuint SHARED_VERTEX_BUFFER;
static GLuint SHARED_INDEX_BUFFER;

+ (GLuint)sharedVertexArray {
    
    if(!SHARED_VERTEX_ARRAY_IS_CREATED) {
        glGenVertexArraysOES(1, &SHARED_VERTEX_ARRAY);
        glBindVertexArrayOES(SHARED_VERTEX_ARRAY);
        
        glGenBuffers(1, &SHARED_VERTEX_BUFFER);
        glBindBuffer(GL_ARRAY_BUFFER, SHARED_VERTEX_BUFFER);
        glBufferData(GL_ARRAY_BUFFER, 24 * sizeof(VertexAttribs), Vertices, GL_STATIC_DRAW);
        
        glGenBuffers(1, &SHARED_INDEX_BUFFER);
        glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, SHARED_INDEX_BUFFER);
        glBufferData(GL_ELEMENT_ARRAY_BUFFER, 36 * sizeof(GLubyte), Indices, GL_STATIC_DRAW);
        
        glEnableVertexAttribArray(GLKVertexAttribPosition);
        glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(VertexAttribs), (const GLvoid *) offsetof(VertexAttribs, Position));
        glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
        glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(VertexAttribs), (const GLvoid *) offsetof(VertexAttribs, TexCoord));
        glEnableVertexAttribArray(GLKVertexAttribNormal);
        glVertexAttribPointer(GLKVertexAttribNormal, 3, GL_FLOAT, GL_FALSE, sizeof(VertexAttribs), (const GLvoid *) offsetof(VertexAttribs, Normal));
        
        glBindVertexArrayOES(0);
        
        SHARED_VERTEX_ARRAY_IS_CREATED = YES;
    }
    return SHARED_VERTEX_ARRAY;
}

+ (void)destroySharedVertexArray {
    if(SHARED_VERTEX_ARRAY_IS_CREATED) {
        glDeleteBuffers(1, &SHARED_VERTEX_BUFFER);
        glDeleteBuffers(1, &SHARED_INDEX_BUFFER);
        glDeleteVertexArraysOES(1, &SHARED_VERTEX_ARRAY);
        SHARED_VERTEX_ARRAY_IS_CREATED = NO;
    }
}

#pragma mark - Initialization

- (id)initWithTextureNamed:(NSString *)textureName {
    if(self = [super init]) {
        
        NSDictionary * options = @{GLKTextureLoaderOriginBottomLeft: @YES};
        NSError * error;
        self.textureInfo = [GLKTextureLoader textureWithCGImage:[UIImage imageNamed:textureName].CGImage options:options error:&error];
        if(error) {
            NSLog(@"error while loading texture: %@", error.localizedDescription);
        }
        
        NSAssert(self.textureInfo, @"Error loading sprite texture info");
        
    }
    return self;
}

#pragma mark - Draw

- (void)draw {
    [super draw];
    
    self.class.sharedEffect.transform.modelviewMatrix = self.modelViewMatrix;
    self.class.sharedEffect.transform.projectionMatrix = self.camera.projectionMatrix;
    self.class.sharedEffect.texture2d0.name = self.textureInfo.name;
    
    [self.class.sharedEffect prepareToDraw];
    
    glBindVertexArrayOES(self.class.sharedVertexArray);
    glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_BYTE, 0);
    glBindVertexArrayOES(0);
}

#pragma mark - Touch handling

- (int)triangleCount {
    return 36/3;
}

- (void)fillTriangles:(GLKVector3 *)triangles {
    for(int i = 0; i < 36; i++) {
        triangles[i] = Vertices[Indices[i]].Position;
        triangles[i] = Vertices[Indices[i]].Position;
    }
}

@end
