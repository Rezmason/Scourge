package net.rezmason.scourge.textview.core;

import flash.Vector;

@:allow(net.rezmason.scourge.textview.core.BodySegment)
@:allow(net.rezmason.scourge.textview.core.GlyphUtils)
class Glyph {

    public var id(default, null):Int;

    var shape:Vector<Float>;
    var color:Vector<Float>;
    var paint:Vector<Float>;

    var paintHex:Int;
    var visible:Bool;
    var charCode:Int;
    var indexAddress:Int;

    function new(id:Int, shape:Vector<Float>, color:Vector<Float>, paint:Vector<Float>):Void {
        this.id = id;
        this.shape = shape;
        this.color = color;
        this.paint = paint;
        GlyphUtils.makeCorners(this);
        visible = true;
    }
}
