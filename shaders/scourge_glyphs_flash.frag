varying vec3 vColor;
varying vec2 vUV;
varying vec3 vFX;

uniform sampler2D uSampler;
uniform vec4 uDerivMult;

void main(void) {

    float texture = texture2D(uSampler, vUV).b;
    //float deriv = dFdx(vUV.x) * uDerivMult.x;
      float deriv = uDerivMult.x;
    float glyph = 1. - smoothstep(vFX.y - deriv, vFX.y + deriv, texture);

    if (vFX.z > 0.0) glyph = min(1., max(glyph, (1. - texture) * 2. * vFX.y * vFX.z));

    if (vFX.x >= 0.3) glyph *= -1.0;

    gl_FragColor = vec4(vColor * (glyph + vFX.x), 1.0);
}
