package net.rezmason.hypertype.core.rendermethods;

import lime.Assets.getText;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.Texture;

class BloomMethod extends ScreenRenderMethod {
    override function composeShaders() {
        extensions.push('OES_texture_float');
        extensions.push('OES_texture_float_linear');
        vertShader = getText('shaders/bloom.vert');
        fragShader = getText('shaders/bloom.frag');
    }

    override public function start(renderTarget, args) {
        super.start(renderTarget, args);
        program.setFourProgramConstants('uBlurDirection', args[0]);
    }

    override public function drawScreen(textures:Map<String, Texture>) {
        glSys.setDepthTest(false);
        glSys.setBlendFactors(BlendFactor.ONE, BlendFactor.ZERO);
        program.setTextureAt('uTexture', textures['input']);
        glSys.draw(ScreenRenderMethod.indexBuffer, 0, ScreenRenderMethod.TOTAL_TRIANGLES);
    }
}
