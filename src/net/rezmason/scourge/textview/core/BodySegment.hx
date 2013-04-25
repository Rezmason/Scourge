package net.rezmason.scourge.textview.core;

import nme.display3D.IndexBuffer3D;
import nme.display3D.VertexBuffer3D;
import nme.Vector;

import net.rezmason.scourge.textview.utils.BufferUtil;

class BodySegment {

    public var id(default, null):Int;

    public var colorBuffer(default, null):VertexBuffer3D;
    public var shapeBuffer(default, null):VertexBuffer3D;
    public var paintBuffer(default, null):VertexBuffer3D;
    public var indexBuffer(default, null):IndexBuffer3D;

    public var colorVertices(default, null):Vector<Float>;
    public var shapeVertices(default, null):Vector<Float>;
    public var paintVertices(default, null):Vector<Float>;
    public var indices(default, null):Vector<UInt>;

    public var startGlyph(default, null):Int;
    public var numGlyphs(default, null):Int;
    public var numVisibleGlyphs(default, null):Int;

    public var glyphs(default, null):Array<Glyph>;

    public var dirty(default, null):Bool;

    public function new(bufferUtil:BufferUtil, segmentID:Int, glyphs:Array<Glyph>):Void {
        id = segmentID;
        dirty = true;
        this.glyphs = glyphs;
        numGlyphs = glyphs.length;
        numVisibleGlyphs = numGlyphs;

        if (numGlyphs == 0) return;

        createBuffers(bufferUtil);
        createVectors();
        populateVectors(true);
        update();
    }

    inline function createBuffers(bufferUtil:BufferUtil):Void {
        var numGlyphVertices:Int = numGlyphs * Almanac.VERTICES_PER_GLYPH;
        var numGlyphIndices:Int = numGlyphs * Almanac.INDICES_PER_GLYPH;

        shapeBuffer = bufferUtil.createVertexBuffer(numGlyphVertices, Almanac.SHAPE_FLOATS_PER_VERTEX);
        colorBuffer = bufferUtil.createVertexBuffer(numGlyphVertices, Almanac.COLOR_FLOATS_PER_VERTEX);
        paintBuffer = bufferUtil.createVertexBuffer(numGlyphVertices, Almanac.PAINT_FLOATS_PER_VERTEX);
        indexBuffer = bufferUtil.createIndexBuffer(numGlyphIndices);
    }

    inline function createVectors():Void {
        shapeVertices = new Vector<Float>();
        colorVertices = new Vector<Float>();
        paintVertices = new Vector<Float>();
        indices = new Vector<UInt>();
    }

    public inline function populateVectors(insert:Bool = false):Void {
        for (ike in 0...numGlyphs) {
            var glyph:Glyph = glyphs[ike];
            if (insert || glyph.dirty) {
                writeArrayToVector(shapeVertices, ike * Almanac.SHAPE_FLOATS_PER_GLYPH, glyph.shape, Almanac.SHAPE_FLOATS_PER_GLYPH);
                writeArrayToVector(colorVertices, ike * Almanac.COLOR_FLOATS_PER_GLYPH, glyph.color, Almanac.COLOR_FLOATS_PER_GLYPH);
                writeArrayToVector(paintVertices, ike * Almanac.PAINT_FLOATS_PER_GLYPH, glyph.paint, Almanac.PAINT_FLOATS_PER_GLYPH);

                glyph.vertexAddress = ike;
                glyph.dirty = false;

                if (insert) insertGlyph(glyph, ike);

                dirty = true;
            }
        }
    }

    public function update():Void {
        if (!dirty) return;
        dirty = false;

        if (numGlyphs > 0) {
            var numGlyphVertices:Int = numGlyphs * Almanac.VERTICES_PER_GLYPH;
            var numGlyphIndices:Int = numGlyphs * Almanac.INDICES_PER_GLYPH;
            shapeBuffer.uploadFromVector(shapeVertices, 0, numGlyphVertices);
            colorBuffer.uploadFromVector(colorVertices, 0, numGlyphVertices);
            paintBuffer.uploadFromVector(paintVertices, 0, numGlyphVertices);
            indexBuffer.uploadFromVector(indices, 0, numGlyphIndices);
        }
    }

    public function toggleGlyphs(glyphsToToggle:Array<Glyph>, visible:Bool):Int {

        var step:Int = visible ? 1 : -1;
        var offset:Int = visible ? 0 : -1;
        var diff:Int = 0;

        var str = "";
        for (glyph in glyphsToToggle) str += String.fromCharCode(glyph.charCode);

        for (srcGlyph in glyphsToToggle) {

            if (srcGlyph.visible == visible) {
                continue;
            }

            dirty = true;

            srcGlyph.visible = visible;


            var dstGlyph:Glyph = glyphs[numVisibleGlyphs + offset];

            if (srcGlyph != dstGlyph) {
                var srcIndexAddress:Int = srcGlyph.indexAddress;
                var dstIndexAddress:Int = dstGlyph.indexAddress;
                insertGlyph(dstGlyph, srcIndexAddress);
                insertGlyph(srcGlyph, dstIndexAddress);
            }

            numVisibleGlyphs += step;
            diff += step;
        }

        return diff;
    }

    inline function insertGlyph(glyph:Glyph, indexAddress:Int):Void {
        var firstVertIndex:Int = glyph.vertexAddress * Almanac.VERTICES_PER_GLYPH;

        writeArrayToVector(indices, indexAddress * Almanac.INDICES_PER_GLYPH, [
            firstVertIndex + 0, firstVertIndex + 1, firstVertIndex + 2,
            firstVertIndex + 0, firstVertIndex + 2, firstVertIndex + 3,
        ], Almanac.INDICES_PER_GLYPH);

        glyph.indexAddress = indexAddress;
    }

    inline function writeArrayToVector<T>(array:Vector<T>, startIndex:Int, items:Array<T>, numItems:Int):Void {
        for (ike in 0...items.length) array[startIndex + ike] = items[ike];
    }
}
