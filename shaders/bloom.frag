varying vec2 vUV;
uniform sampler2D uTexture;
uniform vec4 uBlurDirection;
uniform float uKernel[25];
uniform int uKernelSize;

void main(void) {
    vec3 sum = vec3(0.0);
    float alphaSum = 0.0;
    vec2 uv = vUV - uBlurDirection.xy * float(uKernelSize) / 2.0;
    
    for ( int ike = 0; ike < uKernelSize; ike++ ) {
        vec4 color = texture2D(uTexture, uv);
        float alpha = color.a * uKernel[ike];
        sum += color.rgb * alpha;
        alphaSum += alpha;
        uv += uBlurDirection.xy;
    };

    gl_FragColor = vec4(sum, alphaSum);
}
