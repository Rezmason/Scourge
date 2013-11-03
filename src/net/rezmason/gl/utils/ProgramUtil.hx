package net.rezmason.gl.utils;

import flash.geom.Matrix3D;
#if flash
    import flash.display.Stage;
    import flash.display3D.Context3DCompareMode;
    import flash.display3D.Context3DProgramType;
    import flash.display3D.Context3DVertexBufferFormat;
    import flash.Vector;
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

        var vec:Vector<Float>;
    #end

    public function new(view:View, context:Context):Void {
        super(view, context);

        #if flash
            vec = new Vector();
        #end
    }

    public inline function loadProgram(vertSource:String, fragSource:String, onLoaded:Program->Void):Void {

        #if flash
            Program.load(context, vertSource, fragSource, onLoaded);
        #else
            var program:Program = GL.createProgram();

            GL.attachShader(program, createShader(vertSource, GL.VERTEX_SHADER));
            GL.attachShader(program, createShader(fragSource, GL.FRAGMENT_SHADER));
            GL.linkProgram(program);

            if (GL.getProgramParameter(program, GL.LINK_STATUS) == 0) {
                var result:String = GL.getProgramInfoLog(program);
                if (result != '') throw result;
            }

            onLoaded(program);
        #end
    }

    #if !flash
        public inline function createShader(source:String, type:Int):GLShader {
            var shader:GLShader = GL.createShader(type);
            GL.shaderSource(shader, source);
            GL.compileShader(shader);
            if (GL.getShaderParameter(shader, GL.COMPILE_STATUS) == 0) {
                trace('--- ERR ---\n$source');
                var err:String = GL.getShaderInfoLog(shader);
                if (err != '') throw err;
            }
            return shader;
        }
    #end

    public inline function setProgram(program:Program):Void {
        #if flash program.attach();
        #else GL.useProgram(program);
        #end
    }

    public inline function setProgramConstantsFromMatrix(program:Program, location:UniformLocation, matrix:Matrix3D):Void {

        #if flash
            program.setUniformFromMatrix(location, matrix, true);
        #else
            GL.uniformMatrix3D(location, false, matrix);
        #end
    }

    public inline function setFourProgramConstants(program:Program, location:UniformLocation, vals:Array<Float>):Void {

        #if flash
            for (i in 0...4) vec[i] = vals[i];
        #end

        #if flash
            program.setUniformFromVector(location, vec, 1);
        #else
            GL.uniform4f(location, vals[0], vals[1], vals[2], vals[3]);
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

    public inline function setTextureAt(program:Program, location:UniformLocation, texture:Texture):Void {

        #if flash
            program.setTextureAt(location, texture);
        #else
            if (texture != null) {
                GL.activeTexture(GL.TEXTURE0);
                GL.bindBitmapDataTexture(cast texture);
                GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);

                // GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR_MIPMAP_NEAREST);
                // GL.generateMipmap(GL.TEXTURE_2D);

                GL.uniform1i(location, 0);
            } else {

            }
        #end
    }

    public inline function setVertexBufferAt(program:Program, location:AttribsLocation, buffer:VertexBuffer, offset:Int = 0, size:Int = -1, ?normalized:Bool):Void {

        #if flash
            if (size < 0) size = 1;
            program.setVertexBufferAt(location, buffer, offset, formats[size]);
        #else
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

    public inline function getUniformLocation(program:Program, name:String):UniformLocation {
        #if flash
            return program.getUniformLocation(name);
        #else
            return GL.getUniformLocation(program, name);
        #end
    }

    public inline function getAttribsLocation(program:Program, name:String):AttribsLocation {
        #if flash
            return program.getAttribLocation(name);
        #else
            return GL.getAttribLocation(program, name);
        #end
    }

    public inline function enableExtension(extName:String):Void {
        #if !flash
            GL.getExtension(extName);
        #end
    }
}
