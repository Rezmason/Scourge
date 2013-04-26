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
    public var glyphTransform:Matrix3D;
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
        glyphs = [];
        init();
        numGlyphs = glyphs.length;
        numVisibleGlyphs = glyphs.length;
        makeSegments();
        numSegments = segments.length;

        transform = new Matrix3D();
        camera = new Matrix3D();
        glyphTransform = new Matrix3D();
        glyphTransform.appendScale(0.0001, 0.0001, 1); // Prevents blowouts
        scissorRectangle = new Rectangle();
    }

    function init():Void {

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
        for (ike in 0...numSegments) numVisibleGlyphs += segments[ike].toggleGlyphs(_glyphs, visible);
        //spitGlyphs();
    }

    public function adjustLayout(stageWidth:Int, stageHeight:Int, rect:Rectangle):Void {

        rect = rect.clone();
        if (stageWidth  == 0) stageWidth  = 1;
        if (stageHeight == 0) stageHeight = 1;
        if (rect.width  == 0) rect.width  = 1 / stageWidth;
        if (rect.height == 0) rect.height = 1 / stageHeight;

        scissorRectangle.x = rect.x * stageWidth;
        scissorRectangle.y = rect.y * stageHeight;
        scissorRectangle.width  = rect.width  * stageWidth;
        scissorRectangle.height = rect.height * stageHeight;

        rect.offset(-0.5, -0.5);
        rect.x *= 2;
        rect.y *= 2;
        rect.width *= 2;
        rect.height *= 2;

        camera.identity();
        camera.appendScale(rect.width, rect.height, 1);
        camera.appendTranslation((rect.left + rect.right) * 0.5, (rect.top + rect.bottom) * -0.5, 0);
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
