package net.rezmason.scourge.textview;

import nme.geom.Matrix3D;
import net.rezmason.utils.FatChar;

class Glyph {
    public var id:Int;
    public var geom:Array<Float>;
    public var color:Array<Float>;
    /*
    public var renderIndex:Int;
    public var renderSegmentIndex:Int;
    */
    public var index:Int;
    public var visible:Bool;
    public var fatChar:FatChar;

    public function new():Void {}
}
