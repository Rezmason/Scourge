varying vec3 vColor;
varying vec3 vUV;
varying vec3 vFX;

uniform sampler2D uSampler;
uniform vec4 uDerivMult;

void main(void) {

    float texture = texture2D(uSampler, vUV.xy).r * vUV.z;
    
      float deriv = uDerivMult.x * min(dFdx(vUV.x), -dFdy(vUV.y));
    //float deriv = uDerivMult.x;
    float glyph = 1. - smoothstep(vFX.y - deriv, vFX.y + deriv, texture);

    if (vFX.z > 0.0) glyph = clamp((1. + vFX.y - texture) * vFX.z, glyph, 1.);
    glyph = clamp(glyph, 0., 1.);
    if (vFX.x >= 0.3) glyph *= -1.0;
    gl_FragColor = vec4(vColor * (glyph + vFX.x), 1.0);
}
