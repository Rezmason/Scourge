package net.rezmason.scourge.textview.core;

import com.adobe.utils.PerspectiveMatrix3D;
//import haxe.ds.IntMap;
import nme.geom.Matrix3D;
import nme.geom.Rectangle;
import nme.geom.Vector3D;
//import nme.Vector;

import net.rezmason.scourge.textview.utils.BufferUtil;
//import net.rezmason.scourge.textview.utils.Types;

class Body {
    public var segments(default, null):Array<BodySegment>;
    public var id:Int;
    public var transform:Matrix3D;
    public var camera:Matrix3D;
    public var glyphTransform:Matrix3D;
    public var numGlyphs(default, null):Int;
    public var numVisibleGlyphs(default, null):Int;
    public var glyphTexture(default, null):GlyphTexture;
    public var scissorRectangle(default, null):Rectangle;
    public var numSegments(default, null):Int;
    public var crop:Bool;
    public var letterbox:Bool;

    var projection:PerspectiveMatrix3D;

    public var glyphs:Array<Glyph>;

    var bufferUtil:BufferUtil;

    public function new(id:Int, bufferUtil:BufferUtil, glyphTexture:GlyphTexture):Void {
        this.id = id;
        this.bufferUtil = bufferUtil;
        crop = true;
        letterbox = true;
        this.glyphTexture = glyphTexture;
        glyphs = [];

        projection = new PerspectiveMatrix3D();
        projection.perspectiveLH(2, 2, 1, 2);

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

        if (crop) {
            scissorRectangle.x = rect.x * stageWidth;
            scissorRectangle.y = rect.y * stageHeight;
            scissorRectangle.width  = rect.width  * stageWidth;
            scissorRectangle.height = rect.height * stageHeight;
        } else {
            scissorRectangle.x = 0;
            scissorRectangle.y = 0;
            scissorRectangle.width  = stageWidth;
            scissorRectangle.height = stageHeight;
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

    inline function sanitizeLayoutRect(stageWidth:Float, stageHeight:Float, rect:Rectangle):Rectangle {
        rect = rect.clone();
        if (stageWidth  == 0) stageWidth  = 1;
        if (stageHeight == 0) stageHeight = 1;
        if (rect.width  == 0) rect.width  = 1 / stageWidth;
        if (rect.height == 0) rect.height = 1 / stageHeight;
        return rect;
    }

    inline function adjustVP(rect:Rectangle):Void {
        // offset the vanishing point to the rectangle's center
        var vec:Vector3D = new Vector3D();
        camera.copyColumnTo(2, vec);
        vec.x += (rect.left + rect.right  - 1);
        vec.y -= (rect.top  + rect.bottom - 1);
        camera.copyColumnFrom(2, vec);
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
}
