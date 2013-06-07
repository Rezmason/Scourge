package net.rezmason.gl.utils;

import flash.geom.Matrix3D;
#if flash
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;

    import com.wighawag.shaders.glsl.*;
#else
    import openfl.gl.GL;
    import openfl.gl.GLShader;
    import openfl.gl.GLTexture;
#end

import net.rezmason.gl.Types;
import net.rezmason.gl.utils.Util;

class ProgramUtil extends Util {

    #if flash
        static var formats:Array<Context3DVertexBufferFormat> = [
            BYTES_4,
            FLOAT_1,
            FLOAT_2,
            FLOAT_3,
            FLOAT_4,
        ];
    #end

    public inline function createProgram(vertSource:String, fragSource:String):Program {

        #if flash
            var program:GLSLProgram = new GLSLProgram(context);
            program.upload( new GLSLVertexShader(vertSource), new GLSLFragmentShader(fragSource));
            return program;
        #else
            var program:Program = GL.createProgram();

            GL.attachShader(program, createShader(vertSource, GL.VERTEX_SHADER));
            GL.attachShader(program, createShader(fragSource, GL.FRAGMENT_SHADER));
            GL.linkProgram(program);

            if (GL.getProgramParameter(program, GL.LINK_STATUS) == 0) {
                var result:String = GL.getProgramInfoLog(program);
                if (result != "") throw result;
            }

            return program;
        #end
    }

    #if !flash
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
    #end

    public inline function setProgram(program:Program):Void {
        #if flash program.attach();
        #else GL.useProgram(program);
        #end
    }

    public inline function setProgramConstantsFromMatrix(program:Program, name:String, matrix:Matrix3D, ?transpose:Bool):Void {

        #if flash
            program.setUniformFromMatrix(name, matrix, transpose);
        #else
            var location:UniformLocation = GL.getUniformLocation(program, name);
            GL.uniformMatrix3D(location, false, matrix);
        #end
    }

    public inline function setBlendFactors(sourceFactor:BlendFactor, destinationFactor:BlendFactor):Void {
        #if flash
            context.setBlendFactors(sourceFactor, destinationFactor);
        #else
            GL.enable(GL.BLEND);
            GL.blendFunc(sourceFactor, destinationFactor);
        #end
    }

    public inline function setDepthTest(enabled:Bool):Void {
        #if flash
            context.setDepthTest(enabled, Context3DCompareMode.LESS);
        #else
            if (enabled) GL.enable(GL.DEPTH_TEST);
            else GL.disable(GL.DEPTH_TEST);
        #end
    }

    public inline function setTextureAt(program:Program, name:String, texture:Texture):Void {

        #if flash
            program.setTextureAt(name, texture);
        #else
            GL.activeTexture(GL.TEXTURE0);
            GL.bindBitmapDataTexture(cast texture);
            GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);

            // GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_NEAREST);
            // GL.generateMipmap(GL.TEXTURE_2D);

            var location:UniformLocation = GL.getUniformLocation(program, name);
            GL.uniform1i(location, 0);
        #end
    }

    public inline function setVertexBufferAt(program:Program, name:String, buffer:VertexBuffer, offset:Int = 0, size:Int = -1, ?normalized:Bool):Void {

        #if flash
            if (size < 0) size = 1;
            program.setVertexBufferAt(name, buffer, offset, formats[size]);
        #else
            var location:Int = GL.getAttribLocation(program, name);
            if (buffer != null) {
                if (size < 0) size = buffer.footprint;

                GL.bindBuffer(GL.ARRAY_BUFFER, buffer.buf);
                GL.vertexAttribPointer(location, size, GL.FLOAT, normalized, 4 * buffer.footprint, 4 * offset);

                GL.enableVertexAttribArray(location);
            } else {
                GL.disableVertexAttribArray(location);
            }
        #end
    }
}
