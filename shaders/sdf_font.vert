attribute vec2 aCorner;
attribute vec2 aUV;
attribute vec3 aColor;
attribute float aHorizontalStretch;
attribute float aScale;
attribute float aCameraSpaceZ;
attribute vec3 aPosition;
attribute float aFontWeight;
attribute float aInverseVideo;
attribute float aAura;

uniform mat4 uBodyTransform;
uniform mat4 uCameraTransform;
uniform vec4 uBodyParams;
uniform vec4 uFontGlyphData;
uniform vec4 uFontSDFData;

varying float vRange;
varying vec2 vInnerUVBounds;
varying vec2 vUVCenter;
varying vec2 vUVOffset;
varying vec3 vColor;
varying float vFontWeight;
varying float vInverseVideo;

void main(void) {

    float inflation = max(0.0, aFontWeight);

    vec4 position = uBodyTransform * vec4(aPosition, 1.0);
    position.z += aCameraSpaceZ;
    position = uCameraTransform * position;
    vec2 glyphRatio = vec2(1.0, uFontSDFData.w);
    vec2 positionInflate = 1.0 + (1.0 / uFontSDFData.xy - 1.0) * inflation;
    position.xy += uBodyParams.xy * aCorner * vec2(aHorizontalStretch, 1.0) * aScale * glyphRatio * positionInflate;

    vColor = aColor * clamp(2.0 - position.z, 0.0, 1.0);
    vec2 glyphSize = uFontGlyphData.zw / uFontGlyphData.xy;
    vec2 uvInflate = 1.0 + (uFontSDFData.xy - 1.0) * (1.0 - inflation);
    vInnerUVBounds = uFontSDFData.xy * glyphSize;
    vUVCenter = aUV + 0.5 * glyphSize;
    vUVOffset = vec2(1., -1.) * aCorner * uvInflate * glyphSize;
    vFontWeight = aFontWeight;
    vInverseVideo = aInverseVideo;
    vRange = uFontSDFData.z;

    position.z = clamp(position.z, 0.0, 1.0);
    gl_Position = position;
}
