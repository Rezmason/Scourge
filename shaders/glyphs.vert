attribute vec3 aPos;
attribute vec2 aCorner;
attribute vec3 aDistort;
attribute vec3 aColor;
attribute vec2 aUV;
attribute vec3 aFX;

uniform vec4 uBodyParams;
uniform mat4 uCameraMat;
uniform mat4 uBodyMat;

varying vec3 vColor;
varying vec3 vUV;
varying vec3 vFX;

void main(void) {
    vec4 pos = uBodyMat * vec4(aPos, 1.0);
    pos.z += aDistort.z;
    pos = uCameraMat * pos;
    pos.xy += uBodyParams.xy * vec2(aCorner.x * aDistort.x, aCorner.y) * aDistort.y;

    vColor = aColor * clamp(2.0 - pos.z, 0.0, 1.0);
    vUV = vec3(aUV, uBodyParams.z);
    vFX = aFX;

    pos.z = clamp(pos.z, 0.0, 1.0);
    gl_Position = pos;
}
