attribute vec3 aPosition;
attribute vec2 aCorner;
attribute float aHorizontalStretch;
attribute float aScale;

attribute vec2 aUV;
attribute vec3 aColor;
attribute float aCameraSpaceZ;
attribute float aFontWeight;
attribute float aInverseVideo;
attribute float aAura;

uniform mat4 uBodyTransform;
uniform mat4 uCameraTransform;
uniform float uBodyGlyphScale;

uniform vec4 uFontGlyphData;
uniform vec4 uFontSDFData;
uniform vec2 uScreenSize;

varying float vRange;
varying vec2 vInnerUVBounds;
varying vec2 vUVCenter;
varying vec2 vUVOffset;
varying vec3 vColor;
varying float vFontWeight;
varying float vInverseVideo;
varying float vAura;

void main(void) {

    vec2 fontGlyphRatio = vec2(1.0, uFontSDFData.w);
    float inflation = max(0.0, aFontWeight);
    vec2 positionInflate = 1.0 + (1.0 / uFontSDFData.xy - 1.0) * inflation;
    vec2 glyphScale = vec2(aHorizontalStretch, 1.0) * aScale;
    vec4 position = uBodyTransform * vec4(aPosition, 1.0);
    position.z += aCameraSpaceZ;
    position = uCameraTransform * position;
    position.xy += 
        aCorner
        * fontGlyphRatio
        * uBodyGlyphScale 
        * glyphScale
        * positionInflate
        / uScreenSize
    ;

    vColor = aColor * clamp(2.0 - position.z, 0.0, 1.0);
    vec2 glyphSize = uFontGlyphData.zw / uFontGlyphData.xy;
    vec2 uvInflate = 1.0 + (uFontSDFData.xy - 1.0) * (1.0 - inflation);
    vInnerUVBounds = uFontSDFData.xy * glyphSize;
    vUVCenter = aUV + 0.5 * glyphSize;
    vUVOffset = vec2(1., -1.) * aCorner * uvInflate * glyphSize;
    vFontWeight = aFontWeight;
    vInverseVideo = aInverseVideo;
    vAura = aAura;
    vRange = uFontSDFData.z;

    position.z = clamp(position.z, 0.0, 1.0);
    gl_Position = position;
}
