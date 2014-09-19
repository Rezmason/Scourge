package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.Data;

class Texture extends Artifact {
    
    @:allow(net.rezmason.gl)
    function setAtProgLocation(prog:NativeProgram, location:UniformLocation, index:Int):Void {}
}
