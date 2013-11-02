varying vec3 vColor;
varying vec2 vUV;
varying float vVid;
varying float vZ;
varying float vFat;

uniform sampler2D uSampler;

void main(void) {

    float mask = texture2D(uSampler, vUV).b;
    float texture;

    if (mask < vFat) {
        texture = 0.;
    } else {
        texture = 1.;
    }

    texture = 1. - texture * smoothstep(vFat - 0.05, vFat + 0.05, mask);

    if (vVid >= 0.3) texture *= -1.0;
    gl_FragColor = vec4(vColor * (texture + vVid) * clamp(2.0 - vZ, 0.0, 1.0), 1.0);
}
