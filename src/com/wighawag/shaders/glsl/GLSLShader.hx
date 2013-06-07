package com.wighawag.shaders.glsl;


import flash.utils.ByteArray;
import flash.display3D.Program3D;
import flash.Vector;
import flash.display3D.textures.Texture;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.VertexBuffer3D;
import flash.display3D.Context3D;
import flash.geom.Matrix3D;
import flash.display3D.Context3DProgramType;
import com.wighawag.shaders.ShaderUtils;

using haxe.JSON;

import haxe.ds.StringMap;

typedef AgalInfoData = {
    types : Dynamic,
    consts : Dynamic,
    storage : Dynamic,
    varnames : Dynamic,
    info : String,
    agalasm : String
}

typedef Constant = Array<Float>;

class AgalInfo{
    public var types : StringMap<String>;
    public var consts : StringMap<Constant>;
    public var storage : StringMap<String>;
    public var varnames : StringMap<String>;
    public var info : String;
    public var agalasm : String;

    public function new(agalInfoData : AgalInfoData) {
        types = populate(agalInfoData.types);
        consts = populate(agalInfoData.consts);
        storage = populate(agalInfoData.storage);
        varnames = populate(agalInfoData.varnames);
        info = agalInfoData.info;
        agalasm = agalInfoData.agalasm;
    }

    private function populate<Type>(data) : StringMap<Type>{
        var hash = new StringMap<Type>();
        for (key in Reflect.fields(data)) {
            hash.set(key, Reflect.field(data, key));
        }
        return hash;
    }
}

class GLSLShader {

    private var agalInfo : AgalInfo;
    public var type : Context3DProgramType;
    public var nativeShader : com.wighawag.shaders.Shader;


    public function new(type : Context3DProgramType, glslSource : String) {

        this.type = type;

        var glsl2agal = new nme.display3D.shaders.GlslToAgal(glslSource, cast(type));
        var agalInfoJson:String = glsl2agal.compile();

        if (agalInfoJson == null) {
            throw "glsl2agal failed.";
        }

        var agalInfoData : AgalInfoData = agalInfoJson.parse();
        agalInfo = new AgalInfo(agalInfoData);
        var agalSource = agalInfo.agalasm;


        nativeShader = ShaderUtils.createShader(type,agalSource);

    }

    public function setUniformFromMatrix(context3D : Context3D, name : String , matrix : Matrix3D,transposedMatrix : Bool = false) : Void{
        var registerIndex = getRegisterIndexForUniform(name);
        context3D.setProgramConstantsFromMatrix(type, registerIndex, matrix, transposedMatrix);
    }

    // expect 4 values
    public function setUniformFromByteArray(context3D, name : String, data:ByteArray, byteArrayOffset:Int) : Void{
        var registerIndex = getRegisterIndexForUniform(name);
        context3D.setProgramConstantsFromByteArray(type, registerIndex, 1, data, byteArrayOffset);
    }

    // TODO do not use vector but use 4 float arguments ?
    // for now it only use the first 4 float in the vector
    public function setUniformFromVector(context3D : Context3D, name : String , vector : Vector<Float>) : Void{
        var registerIndex = getRegisterIndexForUniform(name);
        context3D.setProgramConstantsFromVector(type, registerIndex, vector, 1);
    }

    private function getRegisterIndexForUniform(name : String) : Int{
        //SUBCLASS NEED TO IMPLEMENT
        return -1;
    }

    @:allow(com.wighawag.shaders.glsl)
    private function hasVarying(name:String):Bool {
        return agalInfo.varnames.exists(name);
    }

    public function setup(context3D : Context3D) : Void{
        for (constantName in agalInfo.consts.keys()){
            setUniformFromVector(context3D, constantName, Vector.ofArray(agalInfo.consts.get(constantName)));
        }
    }
}
