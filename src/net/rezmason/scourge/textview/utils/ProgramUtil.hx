package net.rezmason.scourge.textview.utils;

import flash.display3D.Context3DBlendFactor;
import flash.display3D.Context3DCompareMode;
import flash.display3D.Context3DProgramType;
import flash.display3D.Context3DVertexBufferFormat;
import flash.display3D.Program3D;
import flash.display3D.textures.TextureBase;
import flash.display3D.VertexBuffer3D;
import flash.geom.Matrix3D;
import flash.utils.ByteArray;
import flash.Vector;

class ProgramUtil extends Util {

    public function createProgram():Program3D {
        return context.createProgram();
    }

    public function setProgram(program:Program3D):Void {
        context.setProgram(program);
    }

    public function setProgramConstantsFromByteArray(programType:Context3DProgramType, firstRegister:Int, numRegisters:Int, data:ByteArray, byteArrayOffset:UInt):Void {
        context.setProgramConstantsFromByteArray(programType, firstRegister, numRegisters, data, byteArrayOffset);
    }

    public function setProgramConstantsFromMatrix(programType:Context3DProgramType, firstRegister:Int, matrix:Matrix3D, ?transposedMatrix:Bool):Void {
        context.setProgramConstantsFromMatrix(programType, firstRegister, matrix, transposedMatrix);
    }

    public function setProgramConstantsFromVector(programType:Context3DProgramType, firstRegister:Int, data:Vector<Float>, ?numRegisters:Int):Void {
        context.setProgramConstantsFromVector(programType, firstRegister, data, numRegisters);
    }

    public function setBlendFactors(sourceFactor:Context3DBlendFactor, destinationFactor:Context3DBlendFactor):Void {
        context.setBlendFactors(sourceFactor, destinationFactor);
    }

    public function setDepthTest(depthMask:Bool, passCompareMode:Context3DCompareMode):Void {
        context.setDepthTest(depthMask, passCompareMode);
    }

    public function setTextureAt(sampler:Int, texture:TextureBase):Void {
        context.setTextureAt(sampler, texture);
    }

    public function setVertexBufferAt(index:Int, buffer:VertexBuffer3D, ?bufferOffset:Int, ?format:Context3DVertexBufferFormat):Void {
        context.setVertexBufferAt(index, buffer, bufferOffset, format);
    }
}
