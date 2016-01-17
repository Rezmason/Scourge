attribute vec2 aPos;
varying vec2 vUV;

uniform vec2 uBlurDirection;
uniform float uFloatKernelSize;

void main(void) {
    vUV = (aPos + 1.0) / 2.0 - uBlurDirection * uFloatKernelSize / 2.0;
    gl_Position = vec4(aPos, 0., 1.0);
}
