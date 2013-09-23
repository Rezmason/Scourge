attribute vec3 aPos;
attribute vec2 aCorner;
attribute vec3 aPaint;

uniform mat4 uCameraMat;
uniform mat4 uGlyphMat;
uniform mat4 uBodyMat;

varying vec4 vPaint;

void main(void) {

    vPaint = vec4(aPaint, 1.0);

    vec4 pos = uCameraMat * (uBodyMat * vec4(aPos, 1.0));
    pos.xy += (uGlyphMat * vec4(aCorner, 1.0, 1.0)).xy;

    gl_Position = pos;
}
