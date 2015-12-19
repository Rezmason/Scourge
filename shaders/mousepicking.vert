attribute vec3 aPos;
attribute vec2 aCorner;
attribute vec2 aPaint;
attribute vec2 aHitbox;

uniform vec4 uBodyParams;
uniform mat4 uCameraMat;
uniform mat4 uBodyMat;

varying vec4 vPaint;

void main(void) {

    vPaint = vec4(uBodyParams.a, aPaint, 1.0);

    vec4 pos = uCameraMat * (uBodyMat * vec4(aPos, 1.0));
    pos.x += uBodyParams.x * aCorner.x * aHitbox.y * aHitbox.x;
    pos.y += uBodyParams.y * aCorner.y * aHitbox.y;
    pos.z = clamp(pos.z, 0.0, 1.0);
    gl_Position = pos;
}
