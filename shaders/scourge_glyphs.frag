varying vec3 vColor;
varying vec2 vUV;
varying float vVid;
varying float vZ;
varying float vFat;

uniform sampler2D uSampler;
uniform vec4 uDerivMult;

void main(void) {

    float texture = texture2D(uSampler, vUV).b;
    float deriv = (dFdx(vUV.x) + dFdy(vUV.x) + dFdy(vUV.y) + dFdx(vUV.y)) * uDerivMult.x;
    float glyph = 1. - smoothstep(vFat - deriv, vFat + deriv, texture);

    if (vVid >= 0.3) glyph *= -1.0;

    gl_FragColor = vec4(vColor * (glyph + vVid) * clamp(2.0 - vZ, 0.0, 1.0), 1.0);
}
