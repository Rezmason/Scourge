package net.rezmason.hypertype.core.rendermethods;

import lime.Assets.getText;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.Texture;

class CombineMethod extends ScreenRenderMethod {
    override function composeShaders() {
        extensions.push('OES_texture_float');
        extensions.push('OES_texture_float_linear');
        vertShader = getText('shaders/post_process.vert');
        fragShader = getText('shaders/post_process.frag');
    }

    override public function drawScreen(textures:Map<String, Texture>) {
        glSys.setDepthTest(false);
        glSys.setBlendFactors(BlendFactor.ONE, BlendFactor.ZERO);
        program.setTextureAt('uTexture', textures['input']);
        glSys.draw(ScreenRenderMethod.indexBuffer, 0, ScreenRenderMethod.TOTAL_TRIANGLES);
        glSys.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        program.setTextureAt('uTexture', textures['bloom']);
        glSys.draw(ScreenRenderMethod.indexBuffer, 0, ScreenRenderMethod.TOTAL_TRIANGLES);
        #if debug
            glSys.setBlendFactors(BlendFactor.SOURCE_ALPHA, BlendFactor.ONE_MINUS_SOURCE_ALPHA);  
            program.setTextureAt('uTexture', textures['debug']);
            glSys.draw(ScreenRenderMethod.indexBuffer, 0, ScreenRenderMethod.TOTAL_TRIANGLES);
        #end
    }
}
