package net.rezmason.scourge.textview.utils;

import flash.geom.Matrix3D;
import openfl.gl.GL;
import openfl.gl.GLProgram;
import openfl.gl.GLShader;
import openfl.gl.GLTexture;
import openfl.gl.GLUniformLocation;

import net.rezmason.scourge.textview.core.Types;

class ProgramUtil extends Util {

    public inline function createProgram(vertSource:String, fragSource:String):Program {

        var program:GLProgram = GL.createProgram();

        GL.attachShader(program, createShader(vertSource, GL.VERTEX_SHADER));
        GL.attachShader(program, createShader(fragSource, GL.FRAGMENT_SHADER));
        GL.linkProgram(program);

        if (GL.getProgramParameter(program, GL.LINK_STATUS) == 0) {
            var result:String = GL.getProgramInfoLog(program);
            if (result != "") throw result;
        }

        return program;
    }

    public inline function createShader(source:String, type:Int):GLShader {
        var shader:GLShader = GL.createShader(type);
        GL.shaderSource(shader, source);
        GL.compileShader(shader);
        if (GL.getShaderParameter(shader, GL.COMPILE_STATUS) == 0) {
            trace("--- ERR ---\n" + source);
            var err:String = GL.getShaderInfoLog(shader);
            if (err != "") throw err;
        }
        return shader;
    }

    public inline function setProgram(program:Program):Void {
        GL.useProgram(program);
    }

    /*
    public function setProgramConstantsFromByteArray(programType:Context3DProgramType, firstRegister:Int, numRegisters:Int, data:ByteArray, byteArrayOffset:UInt):Void;
    */

    public inline function setProgramConstantsFromMatrix(location:GLUniformLocation, matrix:Matrix3D):Void {
        GL.uniformMatrix3D(location, false, matrix);
    }

    public inline function setProgramConstantsFromVector(location:GLUniformLocation, vec):Void {
        GL.uniform4fv(location, vec);
    }

    public inline function setBlendFactors(sourceFactor:Int, destinationFactor:Int):Void {
        GL.blendFunc(sourceFactor, destinationFactor);
    }

    public inline function setDepthTest(enabled:Bool):Void {
        if (enabled) GL.enable(GL.DEPTH_TEST);
        else GL.disable(GL.DEPTH_TEST);
    }

    public inline function setBlending(enabled:Bool):Void {
        if (enabled) GL.enable(GL.BLEND);
        else GL.disable(GL.BLEND);
    }

    public inline function setTextureAt(location:GLUniformLocation, index:Int, texture:Texture):Void {
        GL.activeTexture(GL.TEXTURE0 + index);
        GL.bindBitmapDataTexture(cast texture);
        GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);

        // GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_NEAREST);
        // GL.generateMipmap(GL.TEXTURE_2D);

        GL.uniform1i(location, 0);
    }

    public inline function setVertexBufferAt(location:Int, buffer:VertexBuffer, offset:Int = 0, size:Int = -1, ?normalized:Bool):Void {
        if (buffer != null) {
            if (size == -1) size = buffer.footprint;

            GL.bindBuffer(GL.ARRAY_BUFFER, buffer.buf);
            GL.vertexAttribPointer(location, size, GL.FLOAT, normalized, 4 * buffer.footprint, 4 * offset);
          //GL.vertexAttribPointer(indx:Int, size:Int, type:Int, normalized:Bool, stride:Int, offset:Int):Void;

            GL.enableVertexAttribArray(location);
        } else {
            GL.disableVertexAttribArray(location);
        }
    }
}
