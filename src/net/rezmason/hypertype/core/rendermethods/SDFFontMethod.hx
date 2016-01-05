package net.rezmason.hypertype.core.rendermethods;

import lime.Assets.getText;
import net.rezmason.hypertype.core.SceneRenderMethod;
import net.rezmason.gl.BlendFactor;

class SDFFontMethod extends SceneRenderMethod {

    inline static var EPSILON:Float = 160;

    public function new():Void {
        super();
        backgroundAlpha = 0;
    }

    override public function start(_):Void {
        super.start(_);
        glSys.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        glSys.setDepthTest(false);

        program.setFourProgramConstants('uEpsilon', [EPSILON, 0, 0, 0]);
    }

    override public function end():Void {
        program.setTextureAt('uSampler', null);
        glSys.setBlendFactors(BlendFactor.ONE, BlendFactor.ZERO);
        glSys.setDepthTest(true);
        super.end();
    }

    override function composeShaders():Void {
        vertShader = getText('shaders/sdf_font.vert');
        fragShader = getText('shaders/sdf_font.frag');
        extensions.push('OES_standard_derivatives');
        extensions.push('OES_texture_float');
        extensions.push('OES_texture_float_linear');
    }

    override function drawBody(body:Body):Void {
        program.setProgramConstantsFromMatrix('uCameraTransform', body.scene.camera.transform);
        program.setProgramConstantsFromMatrix('uBodyTransform', body.concatenatedTransform);
        program.setFourProgramConstants('uFontGlyphData', body.glyphTexture.font.glyphData);
        program.setFourProgramConstants('uFontSDFData', body.glyphTexture.font.sdfData);
        program.setFourProgramConstants('uBodyParams', body.params);
        program.setTextureAt('uFontTexture', body.glyphTexture.texture);
        super.drawBody(body);
    }

    override function setSegment(segment:BodySegment):Void {
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

    override function shouldDrawBody(body:Body) return body.visible;
}

