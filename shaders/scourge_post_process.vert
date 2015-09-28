attribute vec2 aPos;
attribute vec2 aUV;
varying vec2 vUV;

void main(void) {
    vUV = aUV;
    gl_Position = vec4(aPos, 0., 1.0);
}
