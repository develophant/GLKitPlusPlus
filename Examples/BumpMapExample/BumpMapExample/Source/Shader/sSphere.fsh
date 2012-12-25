

precision highp float;

uniform sampler2D s_texture;
uniform sampler2D s_bumpMap;

varying vec2 v_texCoord;
varying vec3 v_normal;

varying vec3 v_bumpAxisX;
varying vec3 v_bumpAxisY;

void main() {
    vec4 pixelColor = texture2D(s_texture, v_texCoord);
    
    float shinyness = 8.0;
    float specularLightBrightness = 0.2;
    float bumpMapOffset = 8.0;
    
    // Create normal offset based on bump map
    vec4 bumpOffset = -0.5 + texture2D(s_bumpMap, v_texCoord);
    vec3 normal = normalize(v_normal + bumpMapOffset * bumpOffset.x * normalize(v_bumpAxisX) - bumpMapOffset * bumpOffset.y * normalize(v_bumpAxisY));
    
    vec3 directionToLight = normalize(vec3(-2.0, 2.0, 1.0));
    
    // Diffuse light
    float diffuseLight = dot(normal, directionToLight);
    if(diffuseLight < 0.0) diffuseLight = 0.0;
    pixelColor = pixelColor * (0.2 + 0.8 * diffuseLight);
    pixelColor.w = 1.0;
    
    // Specular light
    vec3 directionToViewer = vec3(0.0, 0.0, 1.0);
    vec3 reflectanceDirection = normalize(2.0 * dot(normal, directionToLight) * normal - directionToLight);
    float sl = dot(reflectanceDirection, directionToViewer);
    if(sl < 0.0) sl = 0.0;
    float specularLight = pow(sl, shinyness);
    
    pixelColor = pixelColor + specularLightBrightness * specularLight;
    pixelColor.w = 1.0;
    
    gl_FragColor = pixelColor;
}
