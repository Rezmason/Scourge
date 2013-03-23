package net.rezmason.scourge.textview;

import nme.geom.Matrix3D;
import net.rezmason.utils.FatChar;

class Glyph {
    public var id:Int;
    public var shape:Array<Float>;
    public var color:Array<Float>;
    public var visible:Bool;
    public var fatChar:FatChar;

    public var vertexAddress:Int;
    public var indexAddress:Int;

    public function new():Void {}
}
