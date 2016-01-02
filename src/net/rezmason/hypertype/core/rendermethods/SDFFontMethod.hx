package net.rezmason.hypertype.core.rendermethods;

import lime.Assets.getText;

import net.rezmason.hypertype.core.Almanac.*;
import net.rezmason.hypertype.core.BodySegment;
import net.rezmason.hypertype.core.GlyphTexture;
import net.rezmason.hypertype.core.RenderMethod;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.GLTypes;
import net.rezmason.gl.VertexBuffer;

class SDFFontMethod extends RenderMethod {

    inline static var DERIV_MULT:Float = 80;

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
        vertShader = getText('shaders/sdf_font.vert');

        var frag:String = getText('shaders/sdf_font.frag');

        #if js
            glSys.enableExtension('OES_standard_derivatives');
            glSys.enableExtension('OES_texture_float');
            glSys.enableExtension('OES_texture_float_linear');
            fragShader = '
            #extension GL_OES_standard_derivatives : enable
            #extension GL_OES_texture_float : enable
            #extension GL_OES_texture_float_linear : enable
            precision mediump float;
            ' + frag;
        #else
            fragShader = frag;
        #end
    }

    override function setBody(body:Body):Void {
        program.setProgramConstantsFromMatrix('uCameraMat', body.scene.camera.transform);
        program.setProgramConstantsFromMatrix('uBodyMat', body.concatenatedTransform);
        program.setFourProgramConstants('uFontGlyphData', body.glyphTexture.font.glyphData);
        program.setFourProgramConstants('uFontSDFData', body.glyphTexture.font.sdfData);
        program.setFourProgramConstants('uBodyParams', body.params);
        program.setTextureAt('uSampler', body.glyphTexture.texture);
    }

    override public function setSegment(segment:BodySegment):Void {
        var shapeBuffer:VertexBuffer = (segment == null) ? null : segment.shapeBuffer;
        var colorBuffer:VertexBuffer = (segment == null) ? null : segment.colorBuffer;
        program.setVertexBufferAt('aPos',     shapeBuffer, 0, 3); // aPos : [x,y,z]
        program.setVertexBufferAt('aCorner',  shapeBuffer, 3, 2); // aCorner : [ch,hv]
        program.setVertexBufferAt('aDistort', shapeBuffer, 5, 3); // aScale : [h,s,p]
        program.setVertexBufferAt('aColor',   colorBuffer, 0, 3); // aColor : [r,g,b]
        program.setVertexBufferAt('aUV',      colorBuffer, 3, 2); // aUV : [u,v]
        program.setVertexBufferAt('aFX',      colorBuffer, 5, 3); // aFX : [i,f,a]
    }

    override public function drawBody(body:Body) if (body.visible) super.drawBody(body);
}

