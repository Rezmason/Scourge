package net.rezmason.scourge.textview.core.rendermethods;

import lime.Assets.getText;

import net.rezmason.scourge.textview.core.BodySegment;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.RenderMethod;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.Data;
import net.rezmason.gl.VertexBuffer;

class MouseMethod extends RenderMethod {

    public function new():Void {
        super();
        backgroundColor = 0xFFFFFF;
    }

    override public function activate():Void glSys.setProgram(program);

    override function composeShaders():Void {
        vertShader = getText('shaders/mousepicking.vert');
        fragShader = #if !desktop 'precision mediump float;' + #end getText('shaders/mousepicking.frag');
    }

    override function setBody(body:Body):Void {
        program.setProgramConstantsFromMatrix('uCameraMat', body.scene.camera.transform); // uCameraMat contains the camera matrix
        program.setProgramConstantsFromMatrix('uBodyMat', body.concatenatedTransform); // uBodyMat contains the body's matrix
        program.setFourProgramConstants('uBodyParams', body.params); // uBodyParams contains the glyph transform and body paint
    }

    override public function setSegment(segment:BodySegment):Void {
        var shapeBuffer:VertexBuffer = (segment == null) ? null : segment.shapeBuffer;
        var paintBuffer:VertexBuffer = (segment == null) ? null : segment.paintBuffer;
        program.setVertexBufferAt('aPos',    shapeBuffer, 0, 3);
        program.setVertexBufferAt('aCorner', shapeBuffer, 3, 2);
        program.setVertexBufferAt('aPaint',  paintBuffer, 0, 2);
    }
}

