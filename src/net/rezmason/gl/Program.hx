package net.rezmason.gl;

import flash.geom.Matrix3D;
import net.rezmason.gl.Data;
import net.rezmason.gl.GLTypes;

#if flash
    import flash.Vector;
    import flash.display3D.Context3DVertexBufferFormat;
#else
    import openfl.gl.GL;
    import openfl.gl.GLShader;
#end

@:allow(net.rezmason.gl)
class Program {

    var prog:NativeProgram;
    var context:Context;

    #if flash
        static var formats:Array<Context3DVertexBufferFormat> = [
            BYTES_4,
            FLOAT_1,
            FLOAT_2,
            FLOAT_3,
            FLOAT_4,
        ];

        static var vec:Vector<Float> = new Vector();
    #end

    function new(context:Context):Void {
        this.context = context;
    }

    function load(vertSource:String, fragSource:String, onLoaded:Void->Void):Void {
        #if flash
            NativeProgram.load(context, vertSource, fragSource, function(prog) {
                this.prog = prog;
                onLoaded();
            });
        #else
            prog = GL.createProgram();

            function createShader(source:String, type:Int):GLShader {
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

            GL.attachShader(prog, createShader(vertSource, GL.VERTEX_SHADER));
            GL.attachShader(prog, createShader(fragSource, GL.FRAGMENT_SHADER));
            GL.linkProgram(prog);

            if (GL.getProgramParameter(prog, GL.LINK_STATUS) == 0) {
                var result:String = GL.getProgramInfoLog(prog);
                if (result != '') throw result;
            }

            onLoaded();
        #end
    }

    public inline function setProgramConstantsFromMatrix(location:UniformLocation, matrix:Matrix3D):Void {

        #if flash
            prog.setUniformFromMatrix(location, matrix, true);
        #else
            GL.uniformMatrix3D(location, false, matrix);
        #end
    }

    public inline function setFourProgramConstants(location:UniformLocation, vals:Array<Float>):Void {

        #if flash
            for (i in 0...4) vec[i] = vals == null ? 0 : vals[i];
        #end

        #if flash
            prog.setUniformFromVector(location, vec, 1);
        #else
            if (vals == null) GL.uniform4f(location, 0, 0, 0, 0);
            else GL.uniform4f(location, vals[0], vals[1], vals[2], vals[3]);
        #end
    }

    public inline function setTextureAt(location:UniformLocation, texture:Null<Texture>, index:Int = 0):Void {
        #if flash
            switch (texture) {
                case null: prog.setTextureAt(location, null);
                case TEX(tex): prog.setTextureAt(location, tex);
                case _:
            }
        #else
            if (texture != null) {
                if (index != -1) {
                    GL.activeTexture(GL.TEXTURE0 + index);
                    switch (texture) {
                        case BMD(bmd): GL.bindBitmapDataTexture(bmd);
                        case TEX(tex): GL.bindTexture(GL.TEXTURE_2D, tex);
                    }
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MAG_FILTER, GL.LINEAR);
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_MIN_FILTER, GL.LINEAR);
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_S, GL.CLAMP_TO_EDGE);
                    GL.texParameteri(GL.TEXTURE_2D, GL.TEXTURE_WRAP_T, GL.CLAMP_TO_EDGE);

                    GL.uniform1i(location, index);
                }
            } else {

            }
        #end
    }

    public inline function setVertexBufferAt(location:AttribsLocation, buffer:VertexBuffer, offset:Int = 0, size:Int = -1, ?normalized:Bool):Void {
        if (size < 0) size = buffer.footprint;
        if (buffer != null) {
            #if flash
                prog.setVertexBufferAt(location, buffer.buf, offset, formats[size]);
            #else
                GL.bindBuffer(GL.ARRAY_BUFFER, buffer.buf);
                GL.vertexAttribPointer(location, size, GL.FLOAT, normalized, 4 * buffer.footprint, 4 * offset);

                GL.enableVertexAttribArray(location);
            #end
        } else {
            #if flash
                prog.setVertexBufferAt(location, null, offset, formats[size]);
            #else
                GL.disableVertexAttribArray(location);
            #end
        }
    }

    public inline function getUniformLocation(name:String):UniformLocation {
        #if flash
            return prog.getUniformLocation(name);
        #else
            return GL.getUniformLocation(prog, name);
        #end
    }

    public inline function getAttribsLocation(name:String):AttribsLocation {
        #if flash
            return prog.getAttribLocation(name);
        #else
            return GL.getAttribLocation(prog, name);
        #end
    }
}
