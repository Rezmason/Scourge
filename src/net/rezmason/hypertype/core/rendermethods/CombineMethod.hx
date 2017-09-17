package net.rezmason.hypertype.core.rendermethods;

import lime.Assets.getText;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.Texture;

class CombineMethod extends ScreenRenderMethod {
    override function composeShaders() {
        vertShader = getText('shaders/post_process.vert');
        fragShader = getText('shaders/post_process.frag');
    }

    override public function drawScreen(textures:Map<String, Texture>) {
        program.setDepthTest(false);
        program.setBlendFactors(BlendFactor.ONE, BlendFactor.ZERO);
        program.setTexture('uBaseTexture', textures['input'], 0);
        program.setTexture('uAlphaMultipliedTexture', textures['bloom'], 1);
        program.draw(ScreenRenderMethod.indexBuffer, 0, ScreenRenderMethod.TOTAL_TRIANGLES);
        #if debug
            program.setBlendFactors(BlendFactor.SOURCE_ALPHA, BlendFactor.ONE_MINUS_SOURCE_ALPHA);  
            program.setTexture('uBaseTexture', textures['debug'], 0);
            program.setTexture('uAlphaMultipliedTexture', ScreenRenderMethod.emptyTexture, 1);
            program.draw(ScreenRenderMethod.indexBuffer, 0, ScreenRenderMethod.TOTAL_TRIANGLES);
        #end
    }

    override public function end() {
        program.setTexture('uAlphaMultipliedTexture', null, 1);
        super.end();
    }
}
