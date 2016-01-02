attribute vec3 aPosition;
attribute vec2 aCorner;
attribute vec2 aGlyphID;
attribute float aHorizontalStretch;
attribute float aScale;

uniform vec4 uBodyParams;
uniform mat4 uCameraTransform;
uniform mat4 uBodyTransform;
uniform vec4 uFontSDFData;

varying vec4 vID;

void main(void) {

    vID = vec4(uBodyParams.z, aGlyphID, 1.0);

    vec4 pos = uCameraTransform * (uBodyTransform * vec4(aPosition, 1.0));
    vec2 glyphRatio = vec2(1.0, uFontSDFData.w);
    pos.xy += uBodyParams.xy * aCorner * vec2(aHorizontalStretch, 1.0) * aScale * glyphRatio;
    pos.z = clamp(pos.z, 0.0, 1.0);
    gl_Position = pos;
}
