package net.rezmason.hypertype.core.rendermethods;

import lime.Assets.getText;
import net.rezmason.gl.BlendFactor;
import net.rezmason.hypertype.core.GlyphBatch;
import net.rezmason.hypertype.core.SceneRenderMethod;
import net.rezmason.math.Vec4;

class HitboxMethod extends SceneRenderMethod {

    public function new():Void {
        super();
        backgroundColor = new Vec4(1, 1, 1);
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

    override function drawBody(sceneGraph:SceneGraph, body:Body):Void {
        program.setMatrix4('uCameraTransform', sceneGraph.camera.transform);
        program.setMatrix4('uBodyTransform', body.concatenatedTransform);
        program.setVector4('uFontSDFData', body.font.sdfData);
        program.setVector4('uBodyParams', body.concatenatedParams);
        program.setVector4('uCameraParams', sceneGraph.camera.params);
        program.setVector4('uScreenParams', sceneGraph.screenParams);
        super.drawBody(sceneGraph, body);
    }

    override function setGlyphBatch(batch:GlyphBatch):Void {
        var geometryBuffer = (batch == null) ? null : batch.geometryBuffer;
        var hitboxBuffer = (batch == null) ? null : batch.hitboxBuffer;
        program.setVertexBuffer('aPosition',    geometryBuffer, 0, 3);
        program.setVertexBuffer('aCorner', geometryBuffer, 3, 2);
        program.setVertexBuffer('aGlyphID',  hitboxBuffer, 0, 2);
        program.setVertexBuffer('aHorizontalStretch', hitboxBuffer, 2, 1);
        program.setVertexBuffer('aScale', hitboxBuffer, 3, 1);
    }

    override function shouldDrawBody(body:Body) return body.isInteractive;
}

