attribute vec3 aPosition;
attribute vec2 aCorner;
attribute vec2 aGlyphID;
attribute float aHorizontalStretch;
attribute float aScale;

uniform vec4 uBodyParams;
uniform vec4 uScreenParams;
uniform mat4 uCameraTransform;
uniform mat4 uBodyTransform;
uniform vec4 uFontSDFData;

varying vec4 vID;

void main(void) {

    vID = vec4(uBodyParams.y, aGlyphID, 1.0);

    vec4 position = uCameraTransform * (uBodyTransform * vec4(aPosition, 1.0));
    vec2 glyphRatio = vec2(1.0, uFontSDFData.w);
    vec2 aspectRatio = vec2(1.0, uScreenParams.x);
    position.xy += uBodyParams.x * aCorner * vec2(aHorizontalStretch, 1.0) * aScale * glyphRatio * aspectRatio;
    position.z = clamp(position.z, 0.0, 1.0);
    gl_Position = position;
}
