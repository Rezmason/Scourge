attribute vec3 aPos;
attribute vec2 aCorner;
attribute float aScale;
attribute float aPop;
attribute vec3 aColor;
attribute vec2 aUV;
attribute float aVid;

uniform mat4 uCameraMat;
uniform mat4 uGlyphMat;
uniform mat4 uBodyMat;

varying vec3 vColor;
varying vec2 vUV;
varying float vVid;
varying float vZ;

void main(void) {
    vec4 pos = uBodyMat * vec4(aPos, 1.0);
    pos.z += aPop;
    pos = uCameraMat * pos;
    pos.xy += ((uGlyphMat * vec4(aCorner, 1.0, 1.0)).xy) * aScale;

    vColor = aColor;
    vUV = aUV;
    vVid = aVid;
    vZ = pos.z;

    pos.z = clamp(pos.z, 0.0, 1.0);
    gl_Position = pos;
}
