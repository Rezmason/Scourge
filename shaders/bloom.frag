varying vec2 vUV;
uniform sampler2D uTexture;
uniform vec2 uBlurDirection;
uniform float uKernel[25];
uniform int uIntKernelSize;

void main(void) {
    vec4 sum = vec4(0.0);
    vec2 uv = vUV;
    for ( int ike = 0; ike < uIntKernelSize; ike++ ) {
        sum += texture2D( uTexture, uv ) * uKernel[ike];
        uv += uBlurDirection;
    };
    gl_FragColor = sum;
}
