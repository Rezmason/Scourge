package net.rezmason.hypertype.core.rendermethods;

import lime.Assets.getText;
import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.GLTypes;
import net.rezmason.gl.VertexBuffer;
import net.rezmason.math.Vec3;
import net.rezmason.hypertype.core.BodySegment;
import net.rezmason.hypertype.core.GlyphTexture;
import net.rezmason.hypertype.core.RenderMethod;

class HitboxMethod extends RenderMethod {

    public function new():Void {
        super();
        backgroundColor = new Vec3(1, 1, 1);
    }

    override public function activate():Void glSys.setProgram(program);

    override function composeShaders():Void {
        vertShader = getText('shaders/hitbox.vert');
        fragShader = #if !desktop 'precision mediump float;' + #end getText('shaders/hitbox.frag');
    }

    override function setBody(body:Body):Void {
        program.setProgramConstantsFromMatrix('uCameraMat', body.scene.camera.transform);
        program.setProgramConstantsFromMatrix('uBodyMat', body.concatenatedTransform);
        program.setFourProgramConstants('uFontSDFData', body.glyphTexture.font.sdfData);
        program.setFourProgramConstants('uBodyParams', body.params); // uBodyParams contains the glyph transform and body paint
    }

    override public function setSegment(segment:BodySegment):Void {
        var geometryBuffer:VertexBuffer = (segment == null) ? null : segment.geometryBuffer;
        var paintBuffer:VertexBuffer = (segment == null) ? null : segment.paintBuffer;
        program.setVertexBufferAt('aPos',    geometryBuffer, 0, 3); // aPos : [x,y,z]
        program.setVertexBufferAt('aCorner', geometryBuffer, 3, 2); // aCorner : [ch,hv]
        program.setVertexBufferAt('aPaint',  paintBuffer, 0, 2); // aPaint : [paint_r,paint_g]
        program.setVertexBufferAt('aHitbox', paintBuffer, 2, 2); // aHitbox : [paint_h,paint_s]
    }

    override public function drawBody(body:Body) if (body.mouseEnabled && body.visible) super.drawBody(body);
}

