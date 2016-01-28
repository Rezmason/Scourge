varying vec2 vUV;
uniform sampler2D uBaseTexture;
uniform sampler2D uAlphaMultipliedTexture;

void main(void) {
    vec4 alphaMultipliedColor = texture2D(uAlphaMultipliedTexture, vUV);
    gl_FragColor = texture2D(uBaseTexture, vUV) + vec4(alphaMultipliedColor.rgb * alphaMultipliedColor.a, 1.0);
}
