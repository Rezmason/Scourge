package net.rezmason.hypertype.core.rendermethods;

import lime.Assets.getText;
import lime.math.Vector4;
import net.rezmason.gl.BlendFactor;
import net.rezmason.hypertype.core.SceneRenderMethod;

class SDFFontMethod extends SceneRenderMethod {

    inline static var EPSILON:Float = 160;

    public function new():Void {
        super();
        backgroundColor.a = 0;
    }

    override public function start(renderTarget, args):Void {
        super.start(renderTarget, args);
        program.setBlendFactors(BlendFactor.ONE, BlendFactor.ONE);
        program.setDepthTest(false);
        program.setFloat('uEpsilon', EPSILON);
    }

    override public function end():Void {
        program.setTexture('uSampler', null);
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
        program.setMatrix4('uCameraTransform', body.stage.camera.transform);
        program.setMatrix4('uBodyTransform', body.concatenatedTransform);
        program.setVector4('uFontGlyphData', body.font.glyphData);
        program.setVector4('uFontSDFData', body.font.sdfData);
        program.setFloat('uBodyGlyphScale', body.glyphScale);
        program.setVector2('uScreenSize', body.stage.camera.screenSize);
        program.setTexture('uFontTexture', body.font.texture);
        super.drawBody(body);
    }

    override function setGlyphBatch(batch:GlyphBatch):Void {
        var geometryBuffer = (batch == null) ? null : batch.geometryBuffer;
        var fontBuffer = (batch == null) ? null : batch.fontBuffer;
        var colorBuffer = (batch == null) ? null : batch.colorBuffer;
        program.setVertexBuffer('aPosition',     geometryBuffer, 0, 3);
        program.setVertexBuffer('aCorner',  geometryBuffer, 3, 2);
        program.setVertexBuffer('aHorizontalStretch', geometryBuffer, 5, 1);
        program.setVertexBuffer('aScale', geometryBuffer, 6, 1);
        program.setVertexBuffer('aCameraSpaceZ', geometryBuffer, 7, 1);
        program.setVertexBuffer('aColor',   colorBuffer, 0, 3);
        program.setVertexBuffer('aInverseVideo',      colorBuffer, 3, 1);
        program.setVertexBuffer('aAura',      colorBuffer, 4, 1);
        program.setVertexBuffer('aUV',      fontBuffer, 0, 2);
        program.setVertexBuffer('aFontWeight',      fontBuffer, 2, 1);
    }

    override function shouldDrawBody(body:Body) return body.visible;
}

