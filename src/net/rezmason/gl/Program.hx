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
class Program extends Artifact {

    public var loaded(default, null):Bool;
    public var onLoad:Void->Void;
    var prog:NativeProgram;
    var vertSource:String;
    var fragSource:String;

    var uniformLocations:Map<String, UniformLocation>;
    var attribsLocations:Map<String, AttribsLocation>;
    
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

    function new(vertSource:String, fragSource:String):Void {
        this.vertSource = vertSource;
        this.fragSource = fragSource;
        loaded = false;
    }

    override function connectToContext(context:Context):Void {
        uniformLocations = new Map();
        attribsLocations = new Map();
        super.connectToContext(context);
        #if flash
            NativeProgram.load(context, vertSource, fragSource, function(prog) {
                this.prog = prog;
                loaded = true;
                if (onLoad != null) onLoad();
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

            loaded = true;
            if (onLoad != null) onLoad();
        #end
    }

    override function disconnectFromContext():Void {
        super.disconnectFromContext();
        #if flash
            prog.dispose();
        #end

        prog = null;
        uniformLocations = null;
        attribsLocations = null;
        loaded = false;
    }

    public inline function setProgramConstantsFromMatrix(uName:String, matrix:Matrix3D):Void {
        var location = getUniformLocation(uName);
        if (location != null) {
            #if flash
                prog.setUniformFromMatrix(location, matrix, true);
            #else
                GL.uniformMatrix3D(location, false, matrix);
            #end
        }
    }

    public inline function setFourProgramConstants(uName:String, vals:Array<Float>):Void {
        var location = getUniformLocation(uName);
        if (location != null) {
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
    }

    public inline function setTextureAt(uName:String, texture:Texture, index:Int = 0):Void {
        var location = getUniformLocation(uName);
        if (location != null) {
            if (texture == null) {
                #if flash
                    prog.setTextureAt(location, null);
                #else
                #end
            } else {
                texture.setAtProgLocation(prog, location, index);
            }
        }
    }

    public inline function setVertexBufferAt(aName:String, buffer:VertexBuffer, offset:Int = 0, size:Int = -1, ?normalized:Bool):Void {
        var location = getAttribsLocation(aName);
        if (location != null) {
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
    }

    inline function getUniformLocation(name:String):UniformLocation {
        if (!uniformLocations.exists(name)) {
            #if flash
                uniformLocations[name] = prog.getUniformLocation(name);
            #else
                uniformLocations[name] = GL.getUniformLocation(prog, name);
            #end
        }
        return uniformLocations[name];
    }

    inline function getAttribsLocation(name:String):AttribsLocation {
        if (!attribsLocations.exists(name)) {
            #if flash
                attribsLocations[name] = prog.getAttribLocation(name);
            #else
                attribsLocations[name] = GL.getAttribLocation(prog, name);
            #end
        }
        return attribsLocations[name];
    }
}
