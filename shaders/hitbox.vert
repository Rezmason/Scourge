attribute vec3 aPos;
attribute vec2 aCorner;
attribute vec2 aPaint;
attribute vec2 aHitbox;

uniform vec4 uBodyParams;
uniform mat4 uCameraMat;
uniform mat4 uBodyMat;
uniform vec4 uFontSDFData;

varying vec4 vPaint;

void main(void) {

    vPaint = vec4(uBodyParams.z, aPaint, 1.0);

    vec4 pos = uCameraMat * (uBodyMat * vec4(aPos, 1.0));
    vec2 glyphRatio = vec2(1.0, uFontSDFData.w);
    pos.xy += uBodyParams.xy * aCorner * vec2(aHitbox.x, 1.0) * aHitbox.y * glyphRatio;
    pos.z = clamp(pos.z, 0.0, 1.0);
    gl_Position = pos;
}
