package com.wighawag.shaders.glsl;

import flash.display3D.Context3D;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.Program3D;
import flash.display3D.VertexBuffer3D;
import flash.display3D.textures.Texture;
import flash.geom.Matrix3D;

class GLSLProgram {

    private var context3D : Context3D;

    private var nativeProgram : Program3D;

    private var vertexShader : GLSLVertexShader;
    private var fragmentShader : GLSLFragmentShader;

    public function new(context3D : Context3D) {
        this.context3D = context3D;
        nativeProgram = context3D.createProgram();
    }

    public inline function upload(vertexShader : GLSLVertexShader, fragmentShader : GLSLFragmentShader) : Void{
        nativeProgram.upload(vertexShader.nativeShader, fragmentShader.nativeShader);
        this.vertexShader = vertexShader;
        this.fragmentShader = fragmentShader;
    }

    public inline function dispose() : Void{
        nativeProgram.dispose();
    }

    public inline function attach() : Void{
        context3D.setProgram(nativeProgram);
        vertexShader.setup(context3D);
        fragmentShader.setup(context3D);
    }

    public inline function detach() : Void{
        context3D.setProgram(null);
    }

    public inline function getAttribLocation(name:String):Int {
        return vertexShader.getRegisterIndex(name);
    }

    public inline function getUniformLocation(name:String):Int {
        var index:Int = -1;
        var flag:Int = 0;

        if (vertexShader.hasVar(name)) {
            index = vertexShader.getRegisterIndex(name);
        } else {
            index = fragmentShader.getRegisterIndex(name);
            flag = 1;
        }

        return makeLoc(index, flag);
    }

    public inline function setUniformFromMatrix(loc:Int, matrix:Matrix3D, transposedMatrix:Bool = false):Void {
        var index:Int = getLocIndex(loc);
        var flag:Int = getLocFlag(loc);
        if (flag == 0) vertexShader.setUniformFromMatrix(context3D,index,matrix, transposedMatrix);
        else if (flag == 1) fragmentShader.setUniformFromMatrix(context3D,index,matrix, transposedMatrix);
    }

    public inline function setVertexUniformFromMatrix(loc:Int, matrix : Matrix3D,transposedMatrix : Bool = false) : Void{
        vertexShader.setUniformFromMatrix(context3D,getLocIndex(loc),matrix, transposedMatrix);
    }

    public inline function setFragmentUniformFromMatrix(loc:Int, matrix : Matrix3D,transposedMatrix : Bool = false) : Void{
        fragmentShader.setUniformFromMatrix(context3D,getLocIndex(loc),matrix, transposedMatrix);
    }

    // TODO set from vector and byte array

    //AGAL only allow texture for fragment shader
    // TODO add a function in cpp to set texture on vertex shader
    public inline function setTextureAt(loc:Int, texture : Texture){
        fragmentShader.setTextureAt(context3D,getLocIndex(loc),texture);
    }

    public inline function setVertexBufferAt(loc : Int, vertexBuffer : VertexBuffer3D, bufferOffset : Int, format : Context3DVertexBufferFormat) : Void{
        vertexShader.setVertexBufferAt(context3D,getLocIndex(loc),vertexBuffer,bufferOffset,format);
    }

    inline function makeLoc(index:Int, flag:Int):Int return ((flag & 0xFF) << 24) | (index & 0x00FFFFFF);
    inline function getLocFlag(loc:Int):Int return (loc >> 24) & 0xFF;
    inline function getLocIndex(loc:Int):Int return loc & 0x00FFFFFF;
}
