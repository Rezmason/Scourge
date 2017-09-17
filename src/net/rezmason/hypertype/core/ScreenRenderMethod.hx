package net.rezmason.hypertype.core;

import lime.graphics.Image;

import net.rezmason.gl.ImageTexture;
import net.rezmason.gl.IndexBuffer;
import net.rezmason.gl.Texture;
import net.rezmason.gl.VertexBuffer;
import net.rezmason.math.Vec4;

class ScreenRenderMethod extends RenderMethod {

    inline static var FLOATS_PER_VERTEX:Int = 2 + 2;
    inline static var TOTAL_VERTICES:Int = 4;
    inline static var TOTAL_TRIANGLES:Int = 2;
    inline static var TOTAL_INDICES:Int = TOTAL_TRIANGLES * 3;

    static var vertexBuffer:VertexBuffer;
    static var indexBuffer:IndexBuffer;
    static var emptyTexture:Texture;

    public function new() {
        super();
        if (emptyTexture == null) emptyTexture = new ImageTexture(new Image(null, 0, 0, 1, 1, 0x00000000));
        if (vertexBuffer == null) {
            vertexBuffer = new VertexBuffer(TOTAL_VERTICES, FLOATS_PER_VERTEX);
            var verts = [
                -1, -1, 0, 0,
                -1,  1, 0, 1,
                 1, -1, 1, 0,
                 1,  1, 1, 1,
            ];
            for (ike in 0...verts.length) vertexBuffer.mod(ike, verts[ike]);
            vertexBuffer.upload();

            indexBuffer = new IndexBuffer(TOTAL_INDICES);
            var ind = [0, 1, 2, 1, 2, 3,];
            for (ike in 0...TOTAL_INDICES) indexBuffer.mod(ike, ind[ike]);
            indexBuffer.upload();
        }
        backgroundColor = new Vec4(1, 0, 1);
    }

    override public function start(renderTarget, args) {
        super.start(renderTarget, args);
        program.setVertexBuffer('aPos', vertexBuffer, 0, 2);
    }

    override public function end() {
        program.setTexture('uTexture', null);
        program.setVertexBuffer('aPos', null, 0, 2);
        super.end();
    }

    public function drawScreen(textures:Map<String, Texture>) {
        
    }
}
