package net.rezmason.gl.glsl2agal;

import flash.Vector;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.TextureBase;
import flash.geom.Matrix3D;
import flash.utils.Endian;
import flash.utils.ByteArray;

import net.rezmason.gl.glsl2agal.GLSL2AGALTypes;

/**

    The net.rezmason.gl.glsl2agal package is derived from the NME contributions
    of Ronan Sandford (aka @wighawag) toward cross-platform Stage3D support:

    https://github.com/wighawag/NMEStage3DTest

    While functional, the code included here and in the net.rezmason.gl package
    do not represent the primary efforts of the OpenFL community toward a fully
    cross-platform 3D API.

**/

@:allow(net.rezmason.gl.glsl2agal)
class Shader {

    var type(default, null):Context3DProgramType;
    var nativeShader(default, null):ByteArray;
    var varTable:Map<String, String>;
    var constTable:Map<Int, Vector<Float>>;

    function new(agal:AGALOutput) {

        type = agal.type;
        var json:Dynamic = agal.json;
        populateVarTable(json.varnames);
        populateConstTable(json.consts);
        nativeShader = agal.nativeShader;
        nativeShader.endian = Endian.LITTLE_ENDIAN;
    }

    inline function populateVarTable(sVars:Dynamic<String>):Void {
        varTable = new Map();
        for (name in Reflect.fields(sVars)) varTable[name] = cast Reflect.field(sVars, name);
    }

    inline function populateConstTable(sConsts:Dynamic<Array<Float>>):Void {
        constTable = new Map();
        for (name in Reflect.fields(sConsts))
            constTable[getRegisterIndex(name)] = Vector.ofArray(Reflect.field(sConsts, name));
    }

    inline function setup(context3D:Context3D):Void {
        for (index in constTable.keys()) setUniformFromVector(context3D, index, constTable[index], 1);
    }

    inline function setUniformFromMatrix(context3D:Context3D, index:Int, matrix:Matrix3D, transposedMatrix:Bool = false):Void {
        context3D.setProgramConstantsFromMatrix(type, index, matrix, transposedMatrix);
    }

    // expect 4 values
    inline function setUniformFromByteArray(context3D:Context3D, index:Int, data:ByteArray, byteArrayOffset:Int):Void {
        context3D.setProgramConstantsFromByteArray(type, index, 1, data, byteArrayOffset);
    }

    // TODO do not use vector but use 4 float arguments ?
    // for now it only use the first 4 float in the vector
    inline function setUniformFromVector(context3D:Context3D, index:Int, vector:Vector<Float>, count:Int):Void {
        context3D.setProgramConstantsFromVector(type, index, vector, count);
    }

    inline function getRegisterIndex(name:String):Int {
        var registerName:String = varTable[name];
        if(registerName == null) registerName = name;
        return Std.parseInt(registerName.substr(2)); //vc#, fc#, fs#
    }

    inline function setTextureAt(context3D:Context3D, index:Int, texture:TextureBase) {
        if (type == Context3DProgramType.FRAGMENT)
            context3D.setTextureAt( index, texture);
    }

    inline function setVertexBufferAt(context3D:Context3D, index:Int, vertexBuffer:VertexBuffer3D, bufferOffset:Int, format:Context3DVertexBufferFormat):Void {
        if (type == Context3DProgramType.VERTEX )
            context3D.setVertexBufferAt(index, vertexBuffer, bufferOffset, format);
    }

    inline function hasVar(name:String):Bool return varTable.exists(name);
}
