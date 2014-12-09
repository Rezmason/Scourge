package net.rezmason.scourge.textview.core.rendermethods;

import openfl.Assets.getText;

import net.rezmason.scourge.textview.core.Almanac.*;
import net.rezmason.scourge.textview.core.BodySegment;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.RenderMethod;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.Data;
import net.rezmason.gl.VertexBuffer;

class PrettyMethod extends RenderMethod {

    inline static var DERIV_MULT:Float =
    #if flash
        0.3
    #elseif js
        80
    #else
        80
    #end
    ;

    public function new():Void super();

    override public function activate():Void {
        glSys.setProgram(program);
        glSys.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        glSys.setDepthTest(false);

        program.setFourProgramConstants('uDerivMult', [DERIV_MULT, 0, 0, 0]);
    }

    override public function deactivate():Void {
        program.setTextureAt('uSampler', null);
        glSys.setBlendFactors(BlendFactor.ONE, BlendFactor.ZERO);
        glSys.setDepthTest(true);
    }

    override function composeShaders():Void {
        vertShader = getText('shaders/scourge_glyphs.vert');

        var frag:String = getText('shaders/scourge_glyphs.frag');

        #if flash
            fragShader = getText('shaders/scourge_glyphs_flash.frag');
        #elseif js
            glSys.enableExtension("OES_standard_derivatives");
            fragShader = '#extension GL_OES_standard_derivatives : enable \n precision mediump float;' + frag;
        #else
            fragShader = frag;
        #end
    }

    override function setBody(body:Body):Void {
        program.setProgramConstantsFromMatrix('uCameraMat', body.scene.camera.transform); // uCameraMat contains the camera matrix
        program.setProgramConstantsFromMatrix('uBodyMat', body.concatenatedTransform); // uBodyMat contains the body's matrix
        program.setFourProgramConstants('uBodyParams', body.params); // uBodyParams contains the glyph transform and body paint
        program.setTextureAt('uSampler', body.glyphTexture.texture); // uSampler contains our texture
    }

    override public function setSegment(segment:BodySegment):Void {

        var shapeBuffer:VertexBuffer = null;
        var colorBuffer:VertexBuffer = null;

        if (segment != null) {
            shapeBuffer = segment.shapeBuffer;
            colorBuffer = segment.colorBuffer;
        }

        program.setVertexBufferAt('aPos',     shapeBuffer, 0, 3); // aPos contains x,y,z
        program.setVertexBufferAt('aCorner',  shapeBuffer, 3, 2); // aCorner contains h,v
        program.setVertexBufferAt('aDistort', shapeBuffer, 5, 3); // aScale contains h,s,p
        program.setVertexBufferAt('aColor',   colorBuffer, 0, 3); // aColor contains r,g,b
        program.setVertexBufferAt('aUV',      colorBuffer, 3, 2); // aUV contains u,v
        program.setVertexBufferAt('aFX',      colorBuffer, 5, 3); // aFX contains i,f,a
    }
}

