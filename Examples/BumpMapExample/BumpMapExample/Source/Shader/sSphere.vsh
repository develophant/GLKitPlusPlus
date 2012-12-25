


uniform mat4 u_mvMatrix;
uniform mat4 u_pMatrix; 

attribute vec4 a_position; 
attribute vec2 a_texCoord;
attribute vec3 a_bumpAxisX; 
attribute vec3 a_bumpAxisY; 

varying vec2 v_texCoord;

varying vec3 v_normal;
varying vec3 v_bumpAxisX;
varying vec3 v_bumpAxisY;


void main() {
    v_texCoord = a_texCoord;
    
    
    vec4 bumpAxisXInEyeSpace = u_mvMatrix * vec4(a_bumpAxisX, 0.0);
    bumpAxisXInEyeSpace = bumpAxisXInEyeSpace / length(bumpAxisXInEyeSpace);
    v_bumpAxisX = bumpAxisXInEyeSpace.xyz;
    
    vec4 bumpAxisYInEyeSpace = u_mvMatrix * vec4(a_bumpAxisY, 0.0);
    bumpAxisYInEyeSpace = bumpAxisYInEyeSpace / length(bumpAxisYInEyeSpace);
    v_bumpAxisY = bumpAxisYInEyeSpace.xyz;
    
    vec4 normalInEyeSpace = u_mvMatrix * vec4(a_position.xyz, 0.0);
    normalInEyeSpace = normalInEyeSpace / length(normalInEyeSpace);
    v_normal = normalInEyeSpace.xyz;
    gl_Position = u_pMatrix * u_mvMatrix * a_position;
}