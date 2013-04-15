package net.rezmason.scourge.textview.core;

import haxe.ds.IntMap;
import nme.geom.Matrix3D;
import nme.geom.Rectangle;
import nme.Vector;

import net.rezmason.scourge.textview.utils.BufferUtil;
import net.rezmason.scourge.textview.utils.Types;

class Body {
    public var segments(default, null):Array<BodySegment>;
    public var id:Int;
    public var transform:Matrix3D;
    public var camera:Matrix3D;
    public var numGlyphs(default, null):Int;
    public var numVisibleGlyphs(default, null):Int;
    public var glyphTexture(default, null):GlyphTexture;
    public var scissorRectangle:Rectangle;
    public var numSegments(default, null):Int;

    public var glyphs:Array<Glyph>;

    var bufferUtil:BufferUtil;

    public function new(id:Int, bufferUtil:BufferUtil, glyphTexture:GlyphTexture):Void {
        this.id = id;
        this.bufferUtil = bufferUtil;

        this.glyphTexture = glyphTexture;
        init();
        makeGlyphs();
        numGlyphs = glyphs.length;
        numVisibleGlyphs = glyphs.length;
        makeSegments();
        numSegments = segments.length;

        transform = new Matrix3D();
        camera = new Matrix3D();
        scissorRectangle = new Rectangle();
    }

    function init():Void {

    }

    function makeGlyphs():Void {
        glyphs = [];
    }

    function makeSegments():Void {

        segments = [];

        var remainingGlyphs:Int = glyphs.length;
        var startGlyph:Int = 0;

        var segmentID:Int = 0;
        while (startGlyph < numGlyphs) {
            var len:Int = Std.int(Math.min(remainingGlyphs, Almanac.BUFFER_CHUNK));
            segments.push(new BodySegment(bufferUtil, segmentID, glyphs.slice(startGlyph, startGlyph + len)));
            startGlyph += Almanac.BUFFER_CHUNK;
            remainingGlyphs -= Almanac.BUFFER_CHUNK;
            segmentID++;
        }
    }

    public function toggleGlyphs(_glyphs:Array<Glyph>, visible:Bool):Void {

        if (_glyphs == null || _glyphs.length == 0) return;

        // Sort the glyphs by segment, and update the segments
        // Disregard duplicate glyphs, or glyphs whose visibility state doesn't need changing

        var glyphsBySegment:Array<Array<Glyph>> = [];
        var glyphIDs:IntMap<Bool> = new IntMap<Bool>();

        for (segment in segments) glyphsBySegment.push([]);
        for (glyph in _glyphs) {
            if (glyph != null && glyph.visible == !visible && !glyphIDs.exists(glyph.id)) {
                glyphsBySegment[Std.int(glyph.id / Almanac.BUFFER_CHUNK)].push(glyph);
                glyphIDs.set(glyph.id, true);
            }
        }

        for (ike in 0...numSegments) {
            numVisibleGlyphs += segments[ike].toggleGlyphs(glyphsBySegment[ike], visible);
            segments[ike].update();
        }

        //spitGlyphs();
    }

    public function update():Void {
        for (segment in segments) {
            segment.populateVectors();
            segment.update();
        }
    }

    inline function spitGlyphs():Void {
        var str:String = "";
        for (glyph in glyphs) {
            var char:String = String.fromCharCode(glyph.charCode);
            if (!glyph.visible) char = char.toLowerCase();
            str += char;
        }
        trace(str);
    }
}
