uniform sampler2D uFontTexture;
uniform vec4 uEpsilon;

varying float vRange;
varying vec2 vInnerUVBounds;
varying vec2 vUVCenter;
varying vec2 vUVOffset;
varying vec3 vColor;
varying float vFontWeight;
varying float vInverseVideo;

void main(void) {

    vec2 uv = vUVCenter + 0.5 * vUVOffset;
    float heightPercent = texture2D(uFontTexture, uv).r / vRange;
    float deriv = uEpsilon.x * min(dFdx(uv.x), -dFdy(uv.y));
    float brightness = 1.0 - smoothstep(vFontWeight - deriv, vFontWeight + deriv, heightPercent);

    brightness = clamp(brightness, 0.0, 1.0);

    float inverseVideo = vInverseVideo;
    vec2 compare = abs(vUVOffset / vInnerUVBounds);
    if (compare.x > 1.0 || compare.y > 1.0) inverseVideo = 0.0;
    if (inverseVideo >= 0.3) brightness *= -1.0;
    brightness += inverseVideo;

    gl_FragColor = vec4(vColor * brightness, 1.0);
}
