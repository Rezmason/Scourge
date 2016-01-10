varying vec2 vUV;
uniform sampler2D uTexture;
uniform vec4 uBlurDirection;

void main(void) {
    vec4 color = texture2D(uTexture, vUV);
    // gl_FragColor = vec4(color.rg + uBlurDirection.xy, color.ba);
    gl_FragColor = vec4(0.0);
}
