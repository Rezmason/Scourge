package net.rezmason.scourge.textview.core;

import flash.geom.Matrix3D;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.Vector;

import net.rezmason.gl.utils.BufferUtil;
import net.rezmason.utils.Zig;

using net.rezmason.scourge.textview.core.GlyphUtils;

class Body {

    inline static function DEFAULT_VIEW_RECT():Rectangle return new Rectangle(0, 0, 1, 1);
    static var _ids:Int = 0;

    public var segments(default, null):Array<BodySegment>;
    public var id(default, null):Int;
    public var transform:Matrix3D;
    public var camera:Matrix3D;
    public var glyphTransform:Matrix3D;
    public var numGlyphs(default, null):Int;
    public var glyphTexture(default, set):GlyphTexture;
    public var scaleMode(default, null):BodyScaleMode;
    public var catchMouseInRect(default, null):Bool;
    public var viewRect(default, set):Rectangle;
    public var redrawHitSignal(default, null):Zig<Void->Void>;

    var trueNumGlyphs:Int;
    var vanishingPoint:Point;

    var stageWidth:Int;
    var stageHeight:Int;

    var projection:Matrix3D;

    public var glyphs:Array<Glyph>;

    var bufferUtil:BufferUtil;

    function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture):Void {
        stageWidth = 0;
        stageHeight = 0;
        redrawHitSignal = new Zig<Void->Void>();
        id = ++_ids;
        this.bufferUtil = bufferUtil;
        scaleMode = SHOW_ALL;
        catchMouseInRect = true;
        glyphs = [];
        this.glyphTexture = glyphTexture;
        viewRect = DEFAULT_VIEW_RECT();

        projection = makeProjection();
        vanishingPoint = new Point();

        numGlyphs = 0;
        trueNumGlyphs = 0;

        segments = [];
        glyphs = [];

        transform = new Matrix3D();
        camera = new Matrix3D();
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
                    segment = new BodySegment(bufferUtil, segmentID, len, donor);
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

    public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {

        this.stageWidth = stageWidth;
        this.stageHeight = stageHeight;

        var cameraRect:Rectangle = viewRect.clone();
        cameraRect.offset(-0.5, -0.5);
        cameraRect.x *= 2;
        cameraRect.y *= 2;
        cameraRect.width *= 2;
        cameraRect.height *= 2;

        camera.identity();
        camera.append(scaleModeBox(viewRect, scaleMode, stageWidth, stageHeight));
        camera.appendScale(cameraRect.width, cameraRect.height, 1);
        camera.appendTranslation((cameraRect.left + cameraRect.right) * 0.5, (cameraRect.top + cameraRect.bottom) * -0.5, 0);

        camera.appendTranslation(0, 0, 1); // Set the camera back one unit
        camera.append(projection); // Apply perspective

        vanishingPoint.x = (viewRect.left + viewRect.right) * 0.5;
        vanishingPoint.y = (viewRect.top + viewRect.bottom) * 0.5;

        applyVP(0, 0);
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

    inline function applyVP(x:Float, y:Float):Void {
        var rawData:Vector<Float> = camera.rawData;
        rawData[8] =  ((x + vanishingPoint.x) * 2 - 1);
        rawData[9] = -((y + vanishingPoint.y) * 2 - 1);
        camera.rawData = rawData;
    }

    inline static function scaleModeBox(rect:Rectangle, scaleMode:BodyScaleMode, stageWidth:Int, stageHeight:Int):Matrix3D {
        var box:Matrix3D = new Matrix3D();

        var doubleRatio:Float = (rect.width / rect.height) * (stageWidth / stageHeight);

        switch (scaleMode) {
            case EXACT_FIT:
                // Distort the aspect ratio to fit the body in the rectangle
                box.appendScale(1, 1, 1);
            case NO_BORDER:
                // Scale the body uniformly to match the dimension of the largest side of the screen
                if (doubleRatio > 1) box.appendScale(1, doubleRatio, 1);
                else box.appendScale(1 / doubleRatio, 1, 1);
            case NO_SCALE:
                // Perform no scaling logic
                box.appendScale(rect.width / stageWidth, rect.height / stageHeight, 1);
            case SHOW_ALL:
                // Scale the body uniformly to match the dimension of the smallest side of the screen
                if (doubleRatio < 1) box.appendScale(1, doubleRatio, 1);
                else box.appendScale(1 / doubleRatio, 1, 1);
            case WIDTH_FIT:
                // Scale the body uniformly to match the width of the screen
                box.appendScale(1, doubleRatio, 1);
            case HEIGHT_FIT:
                // Scale the body uniformly to match the height of the screen
                box.appendScale(1 / doubleRatio, 1, 1);
        }

        return box;
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
        if (rect == null) rect = DEFAULT_VIEW_RECT();
        if (rect.width <= 0 || rect.height <= 0) throw 'Body view rects cannot be null.';
        viewRect = rect;
        return rect;
    }

    inline function set_glyphTexture(gt:GlyphTexture):GlyphTexture {
        this.glyphTexture = gt;
        for (glyph in glyphs) glyph.set_char(glyph.get_char(), gt.font);
        return gt;
    }
}
