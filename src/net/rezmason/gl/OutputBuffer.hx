package net.rezmason.gl;

import net.rezmason.gl.GLTypes;

class OutputBuffer extends Artifact {

    public var width(default, null):Int;
    public var height(default, null):Int;

    public function resize(width:Int, height:Int):Bool {
        if (this.width == width && this.height == height) return false;
        this.width = width;
        this.height = height;
        return true;
    }
    
    @:allow(net.rezmason.gl) function activate():Void {}
    @:allow(net.rezmason.gl) function deactivate():Void {}
}
