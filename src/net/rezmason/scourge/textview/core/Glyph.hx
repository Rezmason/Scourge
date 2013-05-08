package net.rezmason.scourge.textview.core;

import nme.geom.Matrix3D;
import net.rezmason.utils.FatChar;
import nme.Vector;

class Glyph {
    public var id:Int;
    public var shape(default, null):Vector<Float>;
    public var color(default, null):Vector<Float>;
    public var paint(default, null):Vector<Float>;
    public var _paint:Int;
    public var visible:Bool;
    public var charCode:Int;
    public var dirty:Bool;

    public var vertexAddress:Int;
    public var indexAddress:Int;

    public function new():Void {
        shape = new Vector<Float>(0, false);
        color = new Vector<Float>(0, false);
        paint = new Vector<Float>(0, false);
    }
}
