//
//  SphereNode.m
//  dgi12Projekt
//
//  Created by Anton Holmberg on 2012-05-25.
//  Copyright (c) 2012 KTH. All rights reserved.
//

#import "SphereNode.h"
#import "REProgram.h"

typedef struct VertexAttribs {
    GLKVector3 position;
    GLKVector3 texCoord;
    GLKVector3 bumpAxisX;
    GLKVector3 bumpAxisY;
} VertexAttribs;

@interface SphereNode () {
}

@property VertexAttribs *attribs;
@property int attribsCount;

@property GLuint vertexArray;
@property GLuint vertexBuffer;

@property GLKTextureInfo *textureInfo;
@property GLKTextureInfo *bumpTextureInfo;

@property REProgram *program;

- (GLKVector3)positionForHorizontalAngle:(float)ha topAngle:(float)ta radius:(float)r;
- (GLKVector3)bumpAxisXForHorizontalAngle:(float)ha topAngle:(float)ta;
- (GLKVector3)bumpAxisYForHorizontalAngle:(float)ha topAngle:(float)ta;

@end

@implementation SphereNode

- (id)initWithResolutionX:(int)resolutionX resolutionY:(int)resolutionY radius:(float)radius {
    if (self = [super init]) {
        
        float r = radius;
        
        self.attribsCount = 2 * resolutionX * (resolutionY - 1);
        
        NSLog(@"attribsCount: %d", self.attribsCount);
        self.attribs = calloc(self.attribsCount, sizeof(VertexAttribs));
        memset(self.attribs, 0, self.attribsCount * sizeof(VertexAttribs));
        
        NSError *error = nil;
        NSDictionary * options = @{GLKTextureLoaderOriginBottomLeft: @YES};
        NSString *texturePath = [[NSBundle mainBundle] pathForResource:@"mars_texture" ofType:@"jpg"];
        self.textureInfo = [GLKTextureLoader textureWithContentsOfFile:texturePath options:options error:&error];
        
        
        if(error) NSLog(@"Error: %@", error);
        NSAssert(self.textureInfo, @"Error loading mars texture info");
        
        NSString *bumpPath = [[NSBundle mainBundle] pathForResource:@"mars_normal_map" ofType:@"png"];
        self.bumpTextureInfo = [GLKTextureLoader textureWithContentsOfFile:bumpPath options:options error:nil];
        NSAssert(self.bumpTextureInfo, @"Error loading mars bump map info");
        
        for(int iy = 0; iy < resolutionY - 1; iy++) {
            for(int ix = 0; ix < resolutionX; ix++) {
                
                int index = iy * 2 * resolutionX + 2 * ix;
                
                float fx = ix/(float)(resolutionX - 1);
                
                float fy = 1 - iy/(float)(resolutionY - 1);
                float nextFY = 1 - (iy + 1)/(float)(resolutionY - 1);
                
                float ha = fx * 2 * M_PI;
                float ta0 = fy * M_PI;
                float ta1 = nextFY * M_PI;
                
                self.attribs[index].position = [self positionForHorizontalAngle:ha topAngle:ta0 radius:r];
                self.attribs[index].texCoord = GLKVector3Make(fx, fy, 0);
                self.attribs[index].bumpAxisX = [self bumpAxisXForHorizontalAngle:ha topAngle:ta0];
                self.attribs[index].bumpAxisY = [self bumpAxisYForHorizontalAngle:ha topAngle:ta0];
                
                self.attribs[index+1].position = [self positionForHorizontalAngle:ha topAngle:ta1 radius:r];
                self.attribs[index+1].texCoord = GLKVector3Make(fx, nextFY, 0);
                self.attribs[index+1].bumpAxisX = [self bumpAxisXForHorizontalAngle:ha topAngle:ta1];
                self.attribs[index+1].bumpAxisY = [self bumpAxisYForHorizontalAngle:ha topAngle:ta1];
            }
        }
        
        self.program = [REProgram programWithVertexFilename:@"sSphere.vsh" fragmentFilename:@"sSphere.fsh"];
        
        [self createVertexArray];
    }
    return self;
}

- (void)dealloc {
    free(self.attribs);
}

- (int)triangleCount {
    return self.attribsCount - 2;
}

- (void)fillTriangles:(GLKVector3 *)triangles {
    for(int i = 0; i < self.triangleCount; i++) {
        triangles[3*i] = self.attribs[i].position;
        triangles[3*i+1] = self.attribs[i+1].position;
        triangles[3*i+2] = self.attribs[i+2].position;
    }
}

#pragma mark - Vertex array

- (void)createVertexArray {
    
    GLint a_position = [self.program attribLocation:@"a_position"];
    GLint a_texCoord = [self.program attribLocation:@"a_texCoord"];
    GLint a_bumpAxisX = [self.program attribLocation:@"a_bumpAxisX"];
    GLint a_bumpAxisY = [self.program attribLocation:@"a_bumpAxisY"];
    
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, self.attribsCount * sizeof(VertexAttribs), self.attribs, GL_STATIC_DRAW);
    
    glEnableVertexAttribArray(a_position);
    glEnableVertexAttribArray(a_texCoord);
    glEnableVertexAttribArray(a_bumpAxisX);
    glEnableVertexAttribArray(a_bumpAxisY);
    
    glVertexAttribPointer(a_position, 3, GL_FLOAT, GL_FALSE, sizeof(VertexAttribs), (const GLvoid *) offsetof(VertexAttribs, position));
    glVertexAttribPointer(a_texCoord, 2, GL_FLOAT, GL_FALSE, sizeof(VertexAttribs), (const GLvoid *) offsetof(VertexAttribs, texCoord));
    glVertexAttribPointer(a_bumpAxisX, 3, GL_FLOAT, GL_FALSE, sizeof(VertexAttribs), (const GLvoid *) offsetof(VertexAttribs, bumpAxisX));
    glVertexAttribPointer(a_bumpAxisY, 3, GL_FLOAT, GL_FALSE, sizeof(VertexAttribs), (const GLvoid *) offsetof(VertexAttribs, bumpAxisY));
    
    glBindVertexArrayOES(0);
    
}

#pragma mark - Bump mapping

- (GLKVector3)bumpAxisXForHorizontalAngle:(float)ha topAngle:(float)ta {
    if(ta == 0) ta = 0.001;
    if(ABS(ta - M_PI) < 0.001) ta = M_PI - 0.001;
    GLKVector3 axis = GLKVector3Normalize(GLKVector3Subtract([self positionForHorizontalAngle:ha + 0.001 topAngle:ta radius:10],
                                                             [self positionForHorizontalAngle:ha - 0.001 topAngle:ta radius:10]));
    if(GLKVector3Length(axis) < 0.99) NSLog(@"too short: hori: %.2f, top: %.2f", ha, ta);
    return axis;
}

- (GLKVector3)bumpAxisYForHorizontalAngle:(float)ha topAngle:(float)ta {
    if(ta == 0) ta = 0.001;
    if(ABS(ta - M_PI) < 0.001) ta = M_PI - 0.001;
    GLKVector3 axis = GLKVector3Normalize(GLKVector3Subtract([self positionForHorizontalAngle:ha topAngle:ta + 0.001 radius:10],
                                                             [self positionForHorizontalAngle:ha topAngle:ta - 0.001 radius:10]));
    
    if(GLKVector3Length(axis) < 0.99) NSLog(@"too short: hori: %.2f, top: %.2f", ha, ta);
    return axis;
}

- (GLKVector3)positionForHorizontalAngle:(float)ha topAngle:(float)ta radius:(float)r {
    return GLKVector3Make(r * sin(ta) * cos(ha), r * cos(ta), r * sin(ta) * sin(ha));
}

- (void)draw {
    [super draw];
    
    [self.program use];
    
    glUniform1i([self.program uniformLocation:@"s_texture"], 0);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, self.textureInfo.name);
    
    glUniform1i([self.program uniformLocation:@"s_bumpMap"], 1);
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, self.bumpTextureInfo.name);
    
    glUniformMatrix4fv([self.program uniformLocation:@"u_mvMatrix"], 1, 0, self.modelViewMatrix.m);
    glUniformMatrix4fv([self.program uniformLocation:@"u_pMatrix"], 1, 0, self.camera.projectionMatrix.m);
    
    glBindVertexArrayOES(self.vertexArray);
    glDrawArrays(GL_TRIANGLE_STRIP, 0, self.attribsCount);
    glBindVertexArrayOES(0);
}

@end
