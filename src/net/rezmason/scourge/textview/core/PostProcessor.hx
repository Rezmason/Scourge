package net.rezmason.scourge.textview.core;

import lime.Assets.getText;

import net.rezmason.gl.BlendFactor;
import net.rezmason.gl.GLTypes;
import net.rezmason.gl.*;
import net.rezmason.utils.santa.Present;

class PostProcessor {

    inline static var FLOATS_PER_VERTEX:Int = 2 + 2;
    inline static var TOTAL_VERTICES:Int = 4;
    inline static var TOTAL_TRIANGLES:Int = 2;
    inline static var TOTAL_INDICES:Int = TOTAL_TRIANGLES * 3;

    public var inputBuffer(default, null):OutputBuffer;
    var inputTexture:Texture;
    var viewportBuffer:ViewportOutputBuffer;
    var glSys:GLSystem;
    var program:Program;
    var vertexBuffer:VertexBuffer;
    var indexBuffer:IndexBuffer;

    public function new() {
        glSys = new Present(GLSystem);

        glSys.enableExtension("OES_texture_float");
        glSys.enableExtension("OES_texture_float_linear");
        
        var textureOutputBuffer = glSys.createTextureOutputBuffer();
        inputTexture = textureOutputBuffer.texture;
        inputBuffer = textureOutputBuffer;
        viewportBuffer = glSys.viewportOutputBuffer;

        // inputBuffer = viewportBuffer;

        var vertices:VertexArray = new VertexArray(TOTAL_VERTICES * FLOATS_PER_VERTEX);
        var up = #if flash 1 #else 0 #end ;
        var verts = [
            -1, -1, 0, up, 
            -1,  1, 0, 1 - up, 
             1, -1, 1, up, 
             1,  1, 1, 1 - up, 
        ];
        for (ike in 0...verts.length) vertices[ike] = verts[ike];
        vertexBuffer = glSys.createVertexBuffer(TOTAL_VERTICES, FLOATS_PER_VERTEX);
        vertexBuffer.uploadFromVector(vertices, 0, TOTAL_VERTICES);

        var indices:IndexArray = new IndexArray(6);
        var ind = [0, 1, 2, 1, 2, 3,];
        for (ike in 0...TOTAL_INDICES) indices[ike] = ind[ike];
        indexBuffer = glSys.createIndexBuffer(TOTAL_INDICES);
        indexBuffer.uploadFromVector(indices, 0, TOTAL_INDICES);

        var extensions = '';
        #if js 
            for (extension in ['GL_OES_texture_float',  'GL_OES_texture_float_linear',]) {
                glSys.enableExtension(extension);
                extensions = '$extensions\n#extension $extension : enable';
            }
            extensions = '$extensions\nprecision mediump float;';
        #end

        var vertShader = extensions + getText('shaders/scourge_post_process.vert');
        var fragShader = extensions + getText('shaders/scourge_post_process.frag');
        program = glSys.createProgram(vertShader, fragShader);
    }

    public function setSize(width, height) {
        inputBuffer.resize(width, height);
        viewportBuffer.resize(width, height);
    }

    public function draw() {
        if (!program.loaded) return;

        glSys.setProgram(program);

        program.setTextureAt('uTexture', inputTexture);
        program.setVertexBufferAt('aPos', vertexBuffer, 0, 2);
        program.setVertexBufferAt('aUV',  vertexBuffer, 2, 2);

        glSys.start(viewportBuffer);
        glSys.clear(1, 0, 1);
        glSys.draw(indexBuffer, 0, TOTAL_TRIANGLES);
        glSys.finish();

        program.setTextureAt('uTexture', null);
        program.setVertexBufferAt('aPos', null, 0, 2);
        program.setVertexBufferAt('aUV',  null, 2, 2);
    }
}
