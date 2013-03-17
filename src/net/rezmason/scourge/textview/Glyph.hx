package net.rezmason.scourge.textview;

import nme.geom.Matrix3D;

typedef Glyph = {
    var id:Int;
    var geom:Array<Float>;
    var color:Array<Float>;
    var renderIndex:Int;
    var renderSegmentIndex:Int;
    var hidden:Bool;
    var charCode:Int;
}
