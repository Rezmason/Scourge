package net.rezmason.scourge.textview;

import nme.geom.Matrix3D;

class Model {
    public var segments:Array<BufferSegment>;
    public var id:Int;
    public var matrix:Matrix3D;
    public var numGlyphs:Int;
    public var numVisibleGlyphs:Int;

    public var glyphs:Array<Glyph>;

    public function new():Void {}
}
