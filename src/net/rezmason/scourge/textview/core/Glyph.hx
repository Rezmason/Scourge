package net.rezmason.scourge.textview.core;

import nme.geom.Matrix3D;
import net.rezmason.utils.FatChar;

class Glyph {
    public var id:Int;
    public var shape(default, null):Array<Float>;
    public var color(default, null):Array<Float>;
    public var paint(default, null):Array<Float>;
    public var _paint:Int;
    public var visible:Bool;
    public var charCode:Int;
    public var dirty:Bool;

    public var vertexAddress:Int;
    public var indexAddress:Int;

    public function new():Void {
        shape = [];
        color = [];
        paint = [];
    }
}
