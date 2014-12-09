attribute vec3 aPos;
attribute vec2 aCorner;
attribute vec2 aPaint;

uniform vec4 uBodyParams;
uniform mat4 uCameraMat;
uniform mat4 uBodyMat;

varying vec4 vPaint;

void main(void) {

    vPaint = vec4(uBodyParams.b, aPaint, 1.0);

    vec4 pos = uCameraMat * (uBodyMat * vec4(aPos, 1.0));
    pos.xy += uBodyParams.xy * aCorner;

    gl_Position = pos;
}
