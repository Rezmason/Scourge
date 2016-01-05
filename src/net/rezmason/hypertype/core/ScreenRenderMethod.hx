package net.rezmason.hypertype.core;

import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.GLSystem;
import net.rezmason.gl.IndexBuffer;
import net.rezmason.gl.Texture;
import net.rezmason.gl.VertexBuffer;
import net.rezmason.math.Vec3;
import net.rezmason.utils.santa.Present;

class ScreenRenderMethod extends RenderMethod {

    inline static var FLOATS_PER_VERTEX:Int = 2 + 2;
    inline static var TOTAL_VERTICES:Int = 4;
    inline static var TOTAL_TRIANGLES:Int = 2;
    inline static var TOTAL_INDICES:Int = TOTAL_TRIANGLES * 3;

    static var vertexBuffer:VertexBuffer;
    static var indexBuffer:IndexBuffer;

    public function new() {
        super();
        glSys = new Present(GLSystem);
        if (vertexBuffer == null) {
            vertexBuffer = glSys.createVertexBuffer(TOTAL_VERTICES, FLOATS_PER_VERTEX);
            var verts = [
                -1, -1, 0, 0,
                -1,  1, 0, 1,
                 1, -1, 1, 0,
                 1,  1, 1, 1,
            ];
            for (ike in 0...verts.length) vertexBuffer.mod(ike, verts[ike]);
            vertexBuffer.upload();

            indexBuffer = glSys.createIndexBuffer(TOTAL_INDICES);
            var ind = [0, 1, 2, 1, 2, 3,];
            for (ike in 0...TOTAL_INDICES) indexBuffer.mod(ike, ind[ike]);
            indexBuffer.upload();
        }
        backgroundColor = new Vec3(1, 0, 1);
    }

    override public function start(renderTarget) {
        super.start(renderTarget);
        program.setVertexBufferAt('aPos', vertexBuffer, 0, 2);
    }

    override public function end() {
        program.setTextureAt('uTexture', null);
        program.setVertexBufferAt('aPos', null, 0, 2);
        super.end();
    }

    public function drawScreen(textures:Array<Texture>, debugTextures:Array<Texture>) {
        glSys.setDepthTest(false);
        
        glSys.setBlendFactors(BlendFactor.ONE, BlendFactor.ZERO);  
        for (texture in textures) {
            program.setTextureAt('uTexture', texture);
            glSys.draw(indexBuffer, 0, TOTAL_TRIANGLES);
        }
        
        glSys.setBlendFactors(BlendFactor.SOURCE_ALPHA, BlendFactor.ONE_MINUS_SOURCE_ALPHA);  
        for (texture in debugTextures) {
            program.setTextureAt('uTexture', texture);
            glSys.draw(indexBuffer, 0, TOTAL_TRIANGLES);
        }
    }
}
