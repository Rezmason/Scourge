package com.wighawag.glsl2agal;

import flash.Vector;
import flash.display3D.Context3D;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.Texture;
import flash.geom.Matrix3D;
import flash.utils.ByteArray;
import com.adobe.utils.AGALMiniAssembler;   // glsl2agal.swf
import nme.display3D.shaders.GlslToAgal;    // agalminiassembler.swf

@:allow(com.wighawag.glsl2agal)
class Shader {

    var type(default, null):Context3DProgramType;
    var nativeShader(default, null):ByteArray;
    var varTable:Map<String, String>;
    var constTable:Map<Int, Vector<Float>>;

    function new(type:Context3DProgramType, glslSource:String) {
        this.type = type;
        var agalInfoData:Dynamic = convertGLSLToAGAL(type, glslSource);
        populateVarTable(agalInfoData.varnames);
        populateConstTable(agalInfoData.consts);
        nativeShader = assmebleAGAL(type, agalInfoData.agalasm);
    }

    inline function convertGLSLToAGAL(type:Context3DProgramType, shaderSource:String):Dynamic {
        return haxe.JSON.Json.parse((new GlslToAgal(shaderSource, cast type)).compile());
    }

    inline function populateVarTable(sVars:Dynamic<String>):Void {
        varTable = new Map();
        for (name in Reflect.fields(sVars)) varTable.set(name, Reflect.field(sVars, name));
    }

    inline function populateConstTable(sConsts:Dynamic<Array<Float>>):Void {
        constTable = new Map();
        for (name in Reflect.fields(sConsts))
            constTable.set(getRegisterIndex(name), Vector.ofArray(Reflect.field(sConsts, name)));
    }

    inline function assmebleAGAL(type:Context3DProgramType, shaderSource:String):ByteArray {
        var assembler = new AGALMiniAssembler ();
        assembler.assemble (cast type, shaderSource);
        return assembler.agalcode;
    }

    inline function setup(context3D:Context3D):Void {
        for (index in constTable.keys()) setUniformFromVector(context3D, index, constTable[index]);
    }

    inline function setUniformFromMatrix(context3D:Context3D, index:Int, matrix:Matrix3D, transposedMatrix:Bool = false):Void {
        context3D.setProgramConstantsFromMatrix(type, index, matrix, transposedMatrix);
    }

    // expect 4 values
    inline function setUniformFromByteArray(context3D, index:Int, data:ByteArray, byteArrayOffset:Int):Void {
        context3D.setProgramConstantsFromByteArray(type, index, 1, data, byteArrayOffset);
    }

    // TODO do not use vector but use 4 float arguments ?
    // for now it only use the first 4 float in the vector
    inline function setUniformFromVector(context3D:Context3D, index:Int, vector:Vector<Float>):Void {
        context3D.setProgramConstantsFromVector(type, index, vector, 1);
    }

    inline function getRegisterIndex(name:String):Int {
        var registerName:String = varTable.get(name);
        if(registerName == null) registerName = name;
        return Std.parseInt(registerName.substr(2)); //vc#, fc#, fs#
    }

    inline function setTextureAt(context3D:Context3D, index:Int, texture:Texture) {
        if (type == Context3DProgramType.FRAGMENT)
            context3D.setTextureAt( index, texture);
    }

    inline function setVertexBufferAt(context3D:Context3D, index:Int, vertexBuffer:VertexBuffer3D, bufferOffset:Int, format:Context3DVertexBufferFormat):Void {
        if (type == Context3DProgramType.VERTEX )
            context3D.setVertexBufferAt(index, vertexBuffer, bufferOffset, format);
    }

    inline function hasVar(name:String):Bool return varTable.exists(name);
}
