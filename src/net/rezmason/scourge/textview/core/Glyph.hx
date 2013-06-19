package net.rezmason.scourge.textview.core;

import flash.Vector;

@:allow(net.rezmason.scourge.textview.core.BodySegment)
@:allow(net.rezmason.scourge.textview.core.GlyphUtils)
class Glyph {

    public var id(default, null):Int;
    public var dirty(default, null):Bool;

    var shape(default, null):Vector<Float>;
    var color(default, null):Vector<Float>;
    var paint(default, null):Vector<Float>;

    var _paint:Int;
    var visible:Bool;
    var charCode:Int;
    var vertexAddress:Int;
    var indexAddress:Int;

    function new(id:Int):Void {
        this.id = id;
        shape = new Vector<Float>(0, false);
        color = new Vector<Float>(0, false);
        paint = new Vector<Float>(0, false);
        visible = true;
    }
}
