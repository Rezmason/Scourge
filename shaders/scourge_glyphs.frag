varying vec3 vColor;
varying vec2 vUV;
varying float vVid;
varying float vZ;

uniform sampler2D uSampler;

void main(void) {
    float texture = texture2D(uSampler, vUV).b - 0.5;
    texture = smoothstep(0.25, 0.75, texture);
    if (vVid >= 0.3) texture *= -1.0;
    gl_FragColor = vec4(vColor * (texture + vVid) * clamp(2.0 - vZ, 0.0, 1.0), 1.0);
}
