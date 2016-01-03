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

    inline static var EPSILON:Float = 160;

    public function new():Void {
        super();
        backgroundAlpha = 0;
    }

    override public function activate():Void {
        glSys.setProgram(program);
        glSys.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        glSys.setDepthTest(false);

        program.setFourProgramConstants('uEpsilon', [EPSILON, 0, 0, 0]);
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
        program.setProgramConstantsFromMatrix('uCameraTransform', body.scene.camera.transform);
        program.setProgramConstantsFromMatrix('uBodyTransform', body.concatenatedTransform);
        program.setFourProgramConstants('uFontGlyphData', body.glyphTexture.font.glyphData);
        program.setFourProgramConstants('uFontSDFData', body.glyphTexture.font.sdfData);
        program.setFourProgramConstants('uBodyParams', body.params);
        program.setTextureAt('uFontTexture', body.glyphTexture.texture);
    }

    override public function setSegment(segment:BodySegment):Void {
        var geometryBuffer = (segment == null) ? null : segment.geometryBuffer;
        var fontBuffer = (segment == null) ? null : segment.fontBuffer;
        var colorBuffer = (segment == null) ? null : segment.colorBuffer;
        program.setVertexBufferAt('aPosition',     geometryBuffer, 0, 3);
        program.setVertexBufferAt('aCorner',  geometryBuffer, 3, 2);
        program.setVertexBufferAt('aHorizontalStretch', geometryBuffer, 5, 1);
        program.setVertexBufferAt('aScale', geometryBuffer, 6, 1);
        program.setVertexBufferAt('aCameraSpaceZ', geometryBuffer, 7, 1);
        program.setVertexBufferAt('aColor',   colorBuffer, 0, 3);
        program.setVertexBufferAt('aInverseVideo',      colorBuffer, 3, 1);
        program.setVertexBufferAt('aAura',      colorBuffer, 4, 1);
        program.setVertexBufferAt('aUV',      fontBuffer, 0, 2);
        program.setVertexBufferAt('aFontWeight',      fontBuffer, 2, 1);
    }

    override public function drawBody(body:Body) if (body.visible) super.drawBody(body);
}

