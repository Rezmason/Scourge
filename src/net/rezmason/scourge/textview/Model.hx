package net.rezmason.scourge.textview;

import nme.geom.Matrix3D;

typedef Model = {
    var segments:Array<BufferSegment>;
    var id:Int;
    var matrix:Matrix3D;
    var numGlyphs:Int;
    var numVisibleGlyphs:Int;

    var glyphs:Array<Glyph>;
}
