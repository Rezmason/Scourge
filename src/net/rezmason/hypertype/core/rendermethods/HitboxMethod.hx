package net.rezmason.hypertype.core.rendermethods;

import lime.Assets.getText;
import net.rezmason.gl.BlendFactor;
import net.rezmason.hypertype.core.BodySegment;
import net.rezmason.hypertype.core.SceneRenderMethod;
import net.rezmason.math.Vec3;

class HitboxMethod extends SceneRenderMethod {

    public function new():Void {
        super();
        backgroundColor = new Vec3(1, 1, 1);
    }

    override function composeShaders():Void {
        vertShader = getText('shaders/hitbox.vert');
        fragShader = getText('shaders/hitbox.frag');
    }

    public override function start(renderTarget, args) {
        super.start(renderTarget, args);
        program.setDepthTest(false);
        program.setBlendFactors(BlendFactor.ONE, BlendFactor.ZERO);
    }

    override function drawBody(body:Body):Void {
        program.setMatrix4('uCameraTransform', body.scene.camera.transform);
        program.setMatrix4('uBodyTransform', body.concatenatedTransform);
        program.setFourProgramConstants('uFontSDFData', body.font.sdfData);
        program.setFourProgramConstants('uBodyParams', body.params);
        super.drawBody(body);
    }

    override function setSegment(segment:BodySegment):Void {
        var geometryBuffer = (segment == null) ? null : segment.geometryBuffer;
        var hitboxBuffer = (segment == null) ? null : segment.hitboxBuffer;
        program.setVertexBufferAt('aPosition',    geometryBuffer, 0, 3);
        program.setVertexBufferAt('aCorner', geometryBuffer, 3, 2);
        program.setVertexBufferAt('aGlyphID',  hitboxBuffer, 0, 2);
        program.setVertexBufferAt('aHorizontalStretch', hitboxBuffer, 2, 1);
        program.setVertexBufferAt('aScale', hitboxBuffer, 3, 1);
    }

    override function shouldDrawBody(body:Body) return body.mouseEnabled && body.visible;
}

