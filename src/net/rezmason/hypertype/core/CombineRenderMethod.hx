package net.rezmason.hypertype.core;

import lime.Assets.getText;

class CombineRenderMethod extends ScreenRenderMethod {
    override function composeShaders() {
        extensions.push('OES_texture_float');
        extensions.push('OES_texture_float_linear');
        vertShader = getText('shaders/post_process.vert');
        fragShader = getText('shaders/post_process.frag');
    }
}
