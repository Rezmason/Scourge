package net.rezmason.scourge.textview.core;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;
import flash.Vector;

import net.rezmason.scourge.textview.utils.BufferUtil;

class Body {
    public var segments(default, null):Array<BodySegment>;
    public var id(default, null):Int;
    public var transform:Matrix3D;
    public var camera:Matrix3D;
    public var glyphTransform:Matrix3D;
    public var numGlyphs(default, null):Int;
    public var numVisibleGlyphs(default, null):Int;
    public var glyphTexture(default, null):GlyphTexture;
    public var scissorRectangle(default, null):Rectangle;
    public var numSegments(default, null):Int;
    public var crop(default, set):Bool;
    public var letterbox:Bool;

    var redrawHitAreas:Void->Void;
    var projection:Matrix3D;

    public var glyphs:Array<Glyph>;

    var bufferUtil:BufferUtil;

    public function new(id:Int, bufferUtil:BufferUtil, glyphTexture:GlyphTexture, redrawHitAreas:Void->Void):Void {
        this.id = id;
        this.bufferUtil = bufferUtil;
        this.redrawHitAreas = redrawHitAreas;
        crop = true;
        letterbox = true;
        this.glyphTexture = glyphTexture;
        glyphs = [];

        projection = makeProjection();

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

        rect = sanitizeLayoutRect(stageWidth, stageHeight, rect);

        if (scissorRectangle != null) {
            scissorRectangle.x = rect.x * stageWidth;
            scissorRectangle.y = rect.y * stageHeight;
            scissorRectangle.width  = rect.width  * stageWidth;
            scissorRectangle.height = rect.height * stageHeight;
        }

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
        for (segment in segments) {
            segment.populateVectors();
            segment.update();
        }
    }

    public function interact(id:Int, interaction:Interaction, x:Float, y:Float/*, delta:Float*/):Void {

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

    inline function set_crop(val:Bool):Bool {
        if (crop != val) scissorRectangle = val ? new Rectangle() : null;
        crop = val;
        return crop;
    }

}
