package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

class Texture extends Artifact {
    
    @:allow(net.rezmason.gl)
    function setAtProgLocation(prog:NativeProgram, location:UniformLocation, index:Int):Void {}
}
