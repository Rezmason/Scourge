package net.rezmason.scourge.textview.core;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;

import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

using net.rezmason.scourge.textview.core.GlyphUtils;

class Body {

    static var _ids:Int = 0;

    public var numGlyphs(default, null):Int;
    public var id(default, null):Int;
    public var transform(default, null):Matrix3D;
    public var glyphScale(default, set):Float;
    public var glyphTexture(default, set):GlyphTexture;
    public var scene(default, null):Scene;
    
    public var redrawHitSignal(default, null):Zig<Void->Void>;
    public var updateSignal(default, null):Zig<Float->Void>;
    public var resizeSignal(default, null):Zig<Void->Void>;
    public var interactionSignal(default, null):Zig<Int->Interaction->Void>;
    public var fontChangedSignal(default, null):Zig<Void->Void>;

    @:allow(net.rezmason.scourge.textview.core) var segments(default, null):Array<BodySegment>;
    @:allow(net.rezmason.scourge.textview.core) var glyphTransform(default, null):Array<Float>;
    
    var trueNumGlyphs:Int;

    var glyphs:Array<Glyph>;

    public function new():Void {
        redrawHitSignal = new Zig();
        updateSignal = new Zig();
        resizeSignal = new Zig();
        interactionSignal = new Zig();
        fontChangedSignal = new Zig();
        id = ++_ids;
        glyphs = [];
        var fontManager:FontManager = new Present(FontManager);
        fontManager.onFontChange.add(updateGlyphTexture);
        glyphTexture = fontManager.defaultFont;

        numGlyphs = 0;
        trueNumGlyphs = 0;

        segments = [];
        glyphs = [];

        transform = new Matrix3D();
        glyphTransform = [0, 0, 0, 0];
        glyphScale = 1;
    }

    public inline function getGlyphByID(id:Int):Glyph return glyphs[id];

    public inline function eachGlyph():Iterator<Glyph> return glyphs.iterator();

    public function growTo(numGlyphs:Int):Void {
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
        for (glyph in glyphs) {
            glyph.set_paint(glyph.get_paint() & 0xFFFF | this.id << 16);
            glyph.set_font(glyphTexture.font);
        }
    }

    @:allow(net.rezmason.scourge.textview.core)
    function resize():Void {
        updateGlyphTransform();
        resizeSignal.dispatch();
    }

    @:allow(net.rezmason.scourge.textview.core)
    function update(delta:Float):Void {
        updateSignal.dispatch(delta);
        for (segment in segments) segment.update();
    }

    @:allow(net.rezmason.scourge.textview.core)
    function setScene(scene:Scene):Void {
        this.scene = scene;
    }

    function updateGlyphTexture(glyphTexture:GlyphTexture):Void {
        if (this.glyphTexture != glyphTexture) {
            this.glyphTexture = glyphTexture;
            updateGlyphTransform();
            for (glyph in glyphs) glyph.set_font(glyphTexture.font);
        }
    }

    inline function set_glyphScale(val:Float):Float {
        glyphScale = val;
        updateGlyphTransform();
        return glyphScale;
    }

    inline function set_glyphTexture(tex:GlyphTexture):GlyphTexture {
        if (tex != null) {
            this.glyphTexture = tex;
            fontChangedSignal.dispatch();
        }
        return glyphTexture;
    }

    inline function updateGlyphTransform():Void {
        if (glyphTexture != null && scene != null) {
            glyphTransform[0] = glyphScale;
            glyphTransform[1] = glyphScale * glyphTexture.font.glyphRatio * scene.stageWidth / scene.stageHeight;
        }
    }
}
