package net.rezmason.gl.glsl2agal;

import openfl.Assets.getBytes;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.Texture;
import flash.geom.Matrix3D;
import flash.utils.ByteArray;
import flash.Vector;

import net.rezmason.gl.glsl2agal.Types;
import net.rezmason.utils.TempAgency;

/**

    The net.rezmason.gl.glsl2agal package is derived from the NME contributions
    of Ronan Sandford (aka @wighawag) toward cross-platform Stage3D support:

    https://github.com/wighawag/NMEStage3DTest

    While functional, the code included here and in the net.rezmason.gl package
    do not represent the primary efforts of the OpenFL community toward a fully
    cross-platform 3D API.

**/

class Program {

    private var context3D:Context3D;
    private var nativeProgram:Program3D;
    private var vertexShader:Shader;
    private var fragmentShader:Shader;

    static var agency:TempAgency<GLSLInput, AGALOutput> = null;

    public static function load(context3D:Context3D, vertSource:String, fragSource:String, onLoaded:Program->Void):Void {

        if (agency == null) agency = new TempAgency(getBytes("flash_workers/GLSL2AGALConverter.swf"));

        var vertShader:Shader = null;
        var fragShader:Shader = null;

        function onWorkDone(agal:AGALOutput):Void {

            var shader:Shader = new Shader(agal);

            if (agal.type == Context3DProgramType.VERTEX) vertShader = shader;
            else fragShader = shader;

            if (vertShader != null && fragShader != null) {
                var program:Program = new Program(context3D);
                program.upload(vertShader, fragShader);
                onLoaded(program);
            }
        }

        agency.addWork({type:Context3DProgramType.VERTEX, source:vertSource}, onWorkDone);
        agency.addWork({type:Context3DProgramType.FRAGMENT, source:fragSource}, onWorkDone);
    }

    public function new(context3D:Context3D) {
        this.context3D = context3D;
        nativeProgram = context3D.createProgram();
    }

    public inline function upload(vertexShader:Shader, fragmentShader:Shader):Void {
        nativeProgram.upload(vertexShader.nativeShader, fragmentShader.nativeShader);
        this.vertexShader = vertexShader;
        this.fragmentShader = fragmentShader;
    }

    public inline function dispose():Void {
        nativeProgram.dispose();
    }

    public inline function attach():Void {
        context3D.setProgram(nativeProgram);
        vertexShader.setup(context3D);
        fragmentShader.setup(context3D);
    }

    public inline function detach():Void {
        context3D.setProgram(null);
    }

    public inline function getAttribLocation(name:String):Int {
        return vertexShader.getRegisterIndex(name);
    }

    public inline function getUniformLocation(name:String):Int {
        var flag:Int = vertexShader.hasVar(name) ? 0 : 1;
        var index:Int = (flag == 0 ? vertexShader : fragmentShader).getRegisterIndex(name);

        return makeLoc(index, flag);
    }

    public inline function setUniformFromMatrix(loc:Int, matrix:Matrix3D, transposedMatrix:Bool = false):Void {
        if (getLocFlag(loc) == 0) vertexShader.setUniformFromMatrix(context3D, getLocIndex(loc), matrix, transposedMatrix);
        else fragmentShader.setUniformFromMatrix(context3D, getLocIndex(loc), matrix, transposedMatrix);
    }

    public inline function setUniformFromVector(loc:Int, vec:Vector<Float>, count:Int):Void {
        if (getLocFlag(loc) == 0) vertexShader.setUniformFromVector(context3D, getLocIndex(loc), vec, count);
        else fragmentShader.setUniformFromVector(context3D, getLocIndex(loc), vec, count);
    }

    public inline function setUniformFromByteArray(loc:Int, data:ByteArray, offset:Int):Void {
        if (getLocFlag(loc) == 0) vertexShader.setUniformFromByteArray(context3D, getLocIndex(loc), data, offset);
        else fragmentShader.setUniformFromByteArray(context3D, getLocIndex(loc), data, offset);
    }

    // TODO set from vector and byte array

    // AGAL only allows texture for fragment shader
    public inline function setTextureAt(loc:Int, texture:Texture) {
        fragmentShader.setTextureAt(context3D, getLocIndex(loc), texture);
    }

    public inline function setVertexBufferAt(loc:Int, vertexBuffer:VertexBuffer3D, bufferOffset:Int, format:Context3DVertexBufferFormat):Void {
        vertexShader.setVertexBufferAt(context3D, getLocIndex(loc), vertexBuffer, bufferOffset, format);
    }

    inline function makeLoc(index:Int, flag:Int):Int return ((flag & 0xFF) << 24) | (index & 0x00FFFFFF);
    inline function getLocFlag(loc:Int):Int return (loc >> 24) & 0xFF;
    inline function getLocIndex(loc:Int):Int return loc & 0x00FFFFFF;
}
