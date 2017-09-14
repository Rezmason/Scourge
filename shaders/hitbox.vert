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
uniform float uTransformWithBody;

varying vec4 vID;








void main(void) {

    vec2 fontGlyphRatio = vec2(1.0, uFontSDFData.w);
    
    
    vec2 glyphScale = vec2(aHorizontalStretch, 1.0) * aScale;
    vec4 position = vec4(aPosition, 1.0);    
    vec2 offset = 
        aCorner
        * fontGlyphRatio
        * uBodyGlyphScale
        * glyphScale
        
    ;

    if (uTransformWithBody == 1.0) {
        // offset = offset / uScreenSize;
        offset *= vec2(0.5, -0.5); // TODO: this may be necessary for non-
        position.xy += offset;
    }

    position = uBodyTransform * position;
    
    position = uCameraTransform * position;
    // if (uTransformWithBody == 1.0) {
    //     offset.x *= -1.0;
    //     offset = (uBodyTransform * vec4(offset, 0, 0)).xy;
    //     offset.x *= -1.0;
    // }
    
    if (uTransformWithBody != 1.0) {
        offset = offset / uScreenSize;
        position.xy += offset;
    }

    vID = vec4(uBodyID, aGlyphID, 1.0);










    position.z = clamp(position.z, 0.0, 1.0);
    gl_Position = position;
}
