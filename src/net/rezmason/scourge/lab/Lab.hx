package net.rezmason.scourge.lab;

import haxe.io.BytesOutput;
import lime.Assets.*;
import lime.math.Matrix4;
import lime.math.Vector4;
import lime.utils.Float32Array;
import net.rezmason.gl.*;
import net.rezmason.math.FelzenszwalbSDF;
import net.rezmason.scourge.waves.Ripple;
import net.rezmason.scourge.waves.WaveFunctions;
import net.rezmason.scourge.waves.WavePool;
import net.rezmason.utils.HalfFloatUtil;
import net.rezmason.utils.Zig;

class Lab {
    var width:Int;
    var height:Int;
    public function new(width:Int, height:Int):Void {
        this.width = width;
        this.height = height;
    }

    function update():Void {}
    function draw():Void {}

    public function render():Void {
        update();
        draw();
    }
}
