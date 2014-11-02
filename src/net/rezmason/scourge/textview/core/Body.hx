package net.rezmason.scourge.textview.core;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;

import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

using net.rezmason.scourge.textview.core.GlyphUtils;

class Body {

    static var _ids:Int = 0;

    public var segments(default, null):Array<BodySegment>;
    public var id(default, null):Int;
    public var transform(default, null):Matrix3D;
    public var camera(default, null):Camera;
    public var glyphTransform:Matrix3D;
    public var numGlyphs(default, null):Int;
    public var glyphTexture(default, null):GlyphTexture;
    public var catchMouseInRect(default, null):Bool;
    public var redrawHitSignal(default, null):Zig<Void->Void>;

    var fontManager:FontManager;
    var trueNumGlyphs:Int;

    var stageWidth:Int;
    var stageHeight:Int;

    public var glyphs:Array<Glyph>;

    function new():Void {
        stageWidth = 0;
        stageHeight = 0;
        redrawHitSignal = new Zig<Void->Void>();
        id = ++_ids;
        catchMouseInRect = true;
        glyphs = [];
        fontManager = new Present(FontManager);
        fontManager.onFontChange.add(updateGlyphTexture);
        glyphTexture = fontManager.defaultFont;

        numGlyphs = 0;
        trueNumGlyphs = 0;

        segments = [];
        glyphs = [];

        transform = new Matrix3D();
        camera = new Camera();
        glyphTransform = new Matrix3D();
        glyphTransform.appendScale(0.0001, 0.0001, 1); // Prevents blowouts
    }

    function growTo(numGlyphs:Int):Void {
        if (trueNumGlyphs < numGlyphs) {

            var oldSegments:Array<BodySegment> = segments;
            var oldGlyphs:Array<Glyph> = glyphs;

            glyphs = [];
            segments = [];

            var remainingGlyphs:Int = numGlyphs;
            var startGlyph:Int = 0;
            var segmentID:Int = 0;

            while (startGlyph < numGlyphs) {
                var len:Int = Std.int(Math.min(remainingGlyphs, Almanac.BUFFER_CHUNK));
                var segment:BodySegment = null;
                var donor:BodySegment = oldSegments[segmentID];

                if (donor != null && donor.numGlyphs == len) {
                    segment = donor;
                    segment.numGlyphs = len;
                } else {
                    segment = new BodySegment(segmentID, len, donor);
                    if (donor != null) donor.destroy();
                }

                segments.push(segment);
                glyphs = glyphs.concat(segment.glyphs);
                startGlyph += Almanac.BUFFER_CHUNK;
                remainingGlyphs -= Almanac.BUFFER_CHUNK;
                segmentID++;
            }

            trueNumGlyphs = numGlyphs;

        } else {
            var remainingGlyphs:Int = numGlyphs;
            for (segment in segments) {
                segment.numGlyphs = Std.int(Math.min(remainingGlyphs, Almanac.BUFFER_CHUNK));
                remainingGlyphs -= Almanac.BUFFER_CHUNK;
            }
        }

        this.numGlyphs = numGlyphs;

        for (ike in numGlyphs...trueNumGlyphs) glyphs[ike].reset();
        for (glyph in glyphs) glyph.set_paint(glyph.get_paint() & 0xFFFF | this.id << 16);
    }

    public function resize(stageWidth:Int, stageHeight:Int):Void {
        this.stageWidth = stageWidth;
        this.stageHeight = stageHeight;
        camera.resize(stageWidth, stageHeight);
    }

    public function update(delta:Float):Void {
        for (segment in segments) segment.update();
    }

    public function receiveInteraction(id:Int, interaction:Interaction):Void {

    }

    /*
    inline function spitGlyphs():Void {
        var str:String = '';
        for (glyph in glyphs) {
            str += glyph.toString();
        }
        trace(str);
    }
    */

    inline function setGlyphScale(sX:Float, sY:Float):Void {
        glyphTransform.identity();
        glyphTransform.appendScale(sX, sY, 1);
    }

    inline function updateGlyphTexture(glyphTexture:GlyphTexture):Void {
        if (this.glyphTexture != glyphTexture) {
            this.glyphTexture = glyphTexture;
            for (glyph in glyphs) glyph.set_char(glyph.get_char(), glyphTexture.font);
        }
    }
}
