varying vec3 vColor;
varying vec2 vUV;
varying float vVid;
varying float vZ;
varying float vFat;

uniform sampler2D uSampler;

void main(void) {

    //float derivate = (dFdx(vUV.x) + dFdy(vUV.x) + dFdy(vUV.y) + dFdx(vUV.y)) * 5.0;
    float derivate = 0.005;
    float dist = texture2D(uSampler, vUV).b;
    float texture = 1. - smoothstep(vFat - derivate, vFat + derivate, dist);

    if (vVid >= 0.3) texture *= -1.0;
    gl_FragColor = vec4(vColor * (texture + vVid) * clamp(2.0 - vZ, 0.0, 1.0), 1.0);
}
