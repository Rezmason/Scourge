attribute vec2 aPos;
varying vec2 vUV;

void main(void) {
    vUV = (aPos + 1.0) / 2.0;
    gl_Position = vec4(aPos, 0., 1.0);
}
