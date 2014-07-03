attribute vec3 aPos;
attribute vec2 aCorner;
attribute vec3 aDistort;
attribute vec3 aColor;
attribute vec2 aUV;
attribute vec3 aFX;

uniform mat4 uCameraMat;
uniform mat4 uGlyphMat;
uniform mat4 uBodyMat;

varying vec3 vColor;
varying vec2 vUV;
varying vec3 vFX;

void main(void) {
    vec4 pos = uBodyMat * vec4(aPos, 1.0);
    pos.z += aDistort.z;
    pos = uCameraMat * pos;
    pos.xy += ((uGlyphMat * vec4(aCorner.x * aDistort.x, aCorner.y, 1.0, 1.0)).xy) * aDistort.y;

    vColor = aColor * clamp(2.0 - pos.z, 0.0, 1.0);
    vUV = aUV;
    vFX = aFX;

    pos.z = clamp(pos.z, 0.0, 1.0);
    gl_Position = pos;
}
