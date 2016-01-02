attribute vec2 aCorner;
attribute vec2 aUV;
attribute vec3 aColor;
attribute vec3 aDistort;
attribute vec3 aPos;
attribute float aFontWeight;
attribute float aInverseVideo;
attribute float aAura;

uniform mat4 uBodyMat;
uniform mat4 uCameraMat;
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

    vec4 pos = uBodyMat * vec4(aPos, 1.0);
    pos.z += aDistort.z;
    pos = uCameraMat * pos;
    vec2 glyphRatio = vec2(1.0, uFontSDFData.w);
    vec2 posInflate = 1.0 + (1.0 / uFontSDFData.xy - 1.0) * inflation;
    pos.xy += uBodyParams.xy * aCorner * vec2(aDistort.x, 1.0) * aDistort.y * glyphRatio * posInflate;

    vColor = aColor * clamp(2.0 - pos.z, 0.0, 1.0);
    vec2 glyphSize = uFontGlyphData.zw / uFontGlyphData.xy;
    vec2 uvInflate = 1.0 + (uFontSDFData.xy - 1.0) * (1.0 - inflation);
    vInnerUVBounds = uFontSDFData.xy * glyphSize;
    vUVCenter = aUV + 0.5 * glyphSize;
    vUVOffset = vec2(1., -1.) * aCorner * uvInflate * glyphSize;
    vFontWeight = aFontWeight;
    vInverseVideo = aInverseVideo;
    vRange = uFontSDFData.z;

    pos.z = clamp(pos.z, 0.0, 1.0);
    gl_Position = pos;
}
