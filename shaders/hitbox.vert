attribute vec3 aPosition;
attribute vec2 aCorner;
attribute float aHorizontalStretch;
attribute float aScale;

attribute vec2 aGlyphID;






uniform mat4 uBodyTransform;
uniform mat4 uCameraTransform;
uniform float uBodyGlyphScale;
uniform float uBodyID;

uniform vec4 uFontSDFData;
uniform vec2 uScreenSize;

varying vec4 vID;








void main(void) {

    vec2 fontGlyphRatio = vec2(1.0, uFontSDFData.w);
    
    
    vec2 glyphScale = vec2(aHorizontalStretch, 1.0) * aScale;
    vec4 position = uBodyTransform * vec4(aPosition, 1.0);
    
    position = uCameraTransform * position;
    position.xy += 
        aCorner
        * fontGlyphRatio
        * uBodyGlyphScale
        * glyphScale
        
        / uScreenSize
    ;

    vID = vec4(uBodyID, aGlyphID, 1.0);










    position.z = clamp(position.z, 0.0, 1.0);
    gl_Position = position;
}
