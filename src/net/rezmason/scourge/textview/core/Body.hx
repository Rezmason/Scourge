package net.rezmason.scourge.textview.core;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.Vector;

import net.rezmason.gl.utils.BufferUtil;

using net.rezmason.scourge.textview.core.GlyphUtils;

class Body {

    static var DEFAULT_VIEW_RECT:Rectangle = new Rectangle(0, 0, 1, 1);

    public var segments(default, null):Array<BodySegment>;
    public var id(default, null):Int;
    public var transform:Matrix3D;
    public var camera:Matrix3D;
    public var glyphTransform:Matrix3D;
    public var numGlyphs(default, null):Int;
    public var numVisibleGlyphs(default, null):Int;
    public var glyphTexture(default, set):GlyphTexture;
    public var numSegments(default, null):Int;
    public var letterbox(default, null):Bool;
    public var catchMouseInRect(default, null):Bool;
    public var viewRect(default, set):Rectangle;

    var redrawHitAreas:Void->Void;
    var projection:Matrix3D;

    public var glyphs:Array<Glyph>;

    var bufferUtil:BufferUtil;

    public function new(bufferUtil:BufferUtil, numGlyphs:Int, glyphTexture:GlyphTexture, redrawHitAreas:Void->Void):Void {
        id = 0;
        this.bufferUtil = bufferUtil;
        this.redrawHitAreas = redrawHitAreas;
        if (this.redrawHitAreas == null) redrawHitAreas = function() {};
        letterbox = true;
        catchMouseInRect = true;
        glyphs = [];
        this.glyphTexture = glyphTexture;
        viewRect = DEFAULT_VIEW_RECT;

        projection = makeProjection();

        this.numGlyphs = numGlyphs;
        numVisibleGlyphs = numGlyphs;
        makeSegments();

        transform = new Matrix3D();
        camera = new Matrix3D();
        glyphTransform = new Matrix3D();
        glyphTransform.appendScale(0.0001, 0.0001, 1); // Prevents blowouts
    }

    @:allow(net.rezmason.scourge.textview.core)
    function setID(id:Int):Void {
        this.id = id << 16;
        for (glyph in glyphs) glyph.set_paint(glyph.get_paint() & 0xFFFF | this.id);
    }

    function makeSegments():Void {

        segments = [];
        glyphs = [];

        var remainingGlyphs:Int = numGlyphs;
        var startGlyph:Int = 0;
        var segmentID:Int = 0;
        while (startGlyph < numGlyphs) {
            var len:Int = Std.int(Math.min(remainingGlyphs, Almanac.BUFFER_CHUNK));
            var segment:BodySegment = new BodySegment(bufferUtil, segmentID, len);
            segments.push(segment);
            glyphs = glyphs.concat(segment.glyphs);
            startGlyph += Almanac.BUFFER_CHUNK;
            remainingGlyphs -= Almanac.BUFFER_CHUNK;
            segmentID++;
        }

        numSegments = segments.length;
    }

    public function toggleGlyphs(_glyphs:Array<Glyph>, visible:Bool):Void {
        if (_glyphs == null || _glyphs.length == 0) return;
        for (ike in 0...numSegments) numVisibleGlyphs += segments[ike].toggleGlyphs(_glyphs, visible);
        //spitGlyphs();
    }

    public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {

        var rect:Rectangle = sanitizeLayoutRect(stageWidth, stageHeight, viewRect);

        var cameraRect:Rectangle = rect.clone();
        cameraRect.offset(-0.5, -0.5);
        cameraRect.x *= 2;
        cameraRect.y *= 2;
        cameraRect.width *= 2;
        cameraRect.height *= 2;

        camera.identity();
        camera.appendScale(cameraRect.width, cameraRect.height, 1);
        camera.appendTranslation((cameraRect.left + cameraRect.right) * 0.5, (cameraRect.top + cameraRect.bottom) * -0.5, 0);

        camera.appendTranslation(0, 0, 1); // Set the camera back one unit
        camera.append(projection); // Apply perspective
        adjustVP(rect);
        if (letterbox) applyLetterbox(rect, stageWidth, stageHeight);
    }

    public function update(delta:Float):Void {
        for (segment in segments) segment.update();
    }

    public function interact(id:Int, interaction:Interaction):Void {

    }

    inline function spitGlyphs():Void {
        var str:String = '';
        for (glyph in glyphs) {
            str += glyph.toString();
        }
        trace(str);
    }

    inline function sanitizeLayoutRect(stageWidth:Float, stageHeight:Float, rect:Rectangle):Rectangle {
        rect = rect.clone();
        if (stageWidth  == 0) stageWidth  = 1;
        if (stageHeight == 0) stageHeight = 1;
        if (rect.width  == 0) rect.width  = 1 / stageWidth;
        if (rect.height == 0) rect.height = 1 / stageHeight;
        return rect;
    }

    inline function adjustVP(rect:Rectangle):Void {
        var rawData:Vector<Float> = camera.rawData;
        rawData[8] += (rect.left + rect.right  - 1);
        rawData[9] -= (rect.top  + rect.bottom - 1);
        camera.rawData = rawData;
    }

    inline function applyLetterbox(rect:Rectangle, stageWidth:Float, stageHeight:Float):Void {
        var letterbox:Matrix3D = new Matrix3D();
        var boxRatio:Float = (rect.width / rect.height) * stageWidth / stageHeight;
        if (boxRatio < 1) letterbox.appendScale(1, boxRatio, 1);
        else letterbox.appendScale(1 / boxRatio, 1, 1);
        camera.prepend(letterbox);
    }

    inline function setGlyphScale(sX:Float, sY:Float):Void {
        glyphTransform.identity();
        glyphTransform.appendScale(sX, sY, 1);
    }

    inline function makeProjection():Matrix3D {
        var mat:Matrix3D = new Matrix3D();
        var rawData:Vector<Float> = mat.rawData;
        rawData[10] =  2;
        rawData[11] =  1;
        rawData[14] = -2;
        rawData[15] =  0;
        mat.rawData = rawData;
        return mat;
    }

    inline function set_viewRect(rect:Rectangle):Rectangle {
        if (rect == null) rect = DEFAULT_VIEW_RECT;
        viewRect = rect;
        return rect;
    }

    inline function set_glyphTexture(gt:GlyphTexture):GlyphTexture {
        this.glyphTexture = gt;
        for (glyph in glyphs) glyph.set_char(glyph.get_char(), gt.font);
        return gt;
    }
}
