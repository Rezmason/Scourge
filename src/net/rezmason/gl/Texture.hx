package net.rezmason.gl;

import net.rezmason.gl.GLTypes;
import net.rezmason.gl.Data;

class Texture {
    
    public function new():Void {}

    @:allow(net.rezmason.gl)
    function setAtProgLocation(prog:NativeProgram, location:UniformLocation, index:Int):Void {}
}
