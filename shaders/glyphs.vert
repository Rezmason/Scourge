attribute vec2 aCorner;
attribute vec2 aUV;
attribute vec3 aColor;
attribute vec3 aDistort;
attribute vec3 aFX;
attribute vec3 aPos;

uniform mat4 uBodyMat;
uniform mat4 uCameraMat;
uniform vec4 uBodyParams;
uniform vec4 uFontGlyphData;
uniform vec4 uFontSDFData;

varying vec2 vInnerUVBounds;
varying vec2 vUVCenter;
varying vec2 vUVOffset;
varying vec3 vColor;
varying vec3 vFX;

void main(void) {

    float inflation = (aFX.z != 0.0) ? 1.0 : max(0.0, aFX.y);

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
    vFX = aFX;

    pos.z = clamp(pos.z, 0.0, 1.0);
    gl_Position = pos;
}
