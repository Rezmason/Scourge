uniform sampler2D uSampler;
uniform vec4 uDerivMult;

varying float vRange;
varying vec2 vInnerUVBounds;
varying vec2 vUVCenter;
varying vec2 vUVOffset;
varying vec3 vColor;
varying vec3 vFX;

void main(void) {

    vec2 uv = vUVCenter + 0.5 * vUVOffset;
    float heightPercent = texture2D(uSampler, uv).r / vRange;
    float deriv = uDerivMult.x * min(dFdx(uv.x), -dFdy(uv.y));
    float fat = vFX.y;
    float brightness = 1.0 - smoothstep(fat - deriv, fat + deriv, heightPercent);

    float aura = vFX.z;
    if (aura > 0.0) brightness = clamp((1.0 - heightPercent) * aura, brightness, 1.);
    
    brightness = clamp(brightness, 0.0, 1.0);

    float inverseVideo = vFX.x;
    vec2 compare = abs(vUVOffset / vInnerUVBounds);
    if (compare.x > 1.0 || compare.y > 1.0) inverseVideo = 0.0;
    if (inverseVideo >= 0.3) brightness *= -1.0;
    brightness += inverseVideo;

    gl_FragColor = vec4(vColor * brightness, 1.0);
}
