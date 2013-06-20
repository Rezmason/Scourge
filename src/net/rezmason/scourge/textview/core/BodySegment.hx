package net.rezmason.scourge.textview.core;

import flash.Vector;

import net.rezmason.gl.VertexBuffer;
import net.rezmason.gl.IndexBuffer;
import net.rezmason.gl.utils.BufferUtil;

using net.rezmason.scourge.textview.core.GlyphUtils;

class BodySegment {

    public var id(default, null):Int;

    public var colorBuffer(default, null):VertexBuffer;
    public var shapeBuffer(default, null):VertexBuffer;
    public var paintBuffer(default, null):VertexBuffer;
    public var indexBuffer(default, null):IndexBuffer;

    public var colorVertices(default, null):Vector<Float>;
    public var shapeVertices(default, null):Vector<Float>;
    public var paintVertices(default, null):Vector<Float>;
    public var indices(default, null):Vector<UInt>;

    public var startGlyph(default, null):Int;
    public var numGlyphs(default, null):Int;
    public var numVisibleGlyphs(default, null):Int;

    public var glyphs(default, null):Array<Glyph>;
    var glyphsByIndex:Array<Glyph>;

    public function new(bufferUtil:BufferUtil, segmentID:Int, numGlyphs:Int):Void {
        if (numGlyphs < 0) numGlyphs = 0;
        id = segmentID;
        glyphsByIndex = [];
        this.numGlyphs = numGlyphs;
        numVisibleGlyphs = numGlyphs;
        createBuffersAndVectors(bufferUtil);
        createGlyphs();
        for (glyph in glyphs) insertGlyph(glyph, glyph.id);
        update();
    }

    inline function createBuffersAndVectors(bufferUtil:BufferUtil):Void {
        var numGlyphVertices:Int = numGlyphs * Almanac.VERTICES_PER_GLYPH;
        var numGlyphIndices:Int = numGlyphs * Almanac.INDICES_PER_GLYPH;

        shapeBuffer = bufferUtil.createVertexBuffer(numGlyphVertices, Almanac.SHAPE_FLOATS_PER_VERTEX);
        colorBuffer = bufferUtil.createVertexBuffer(numGlyphVertices, Almanac.COLOR_FLOATS_PER_VERTEX);
        paintBuffer = bufferUtil.createVertexBuffer(numGlyphVertices, Almanac.PAINT_FLOATS_PER_VERTEX);
        indexBuffer = bufferUtil.createIndexBuffer(numGlyphIndices);

        shapeVertices = new Vector<Float>(numGlyphVertices * Almanac.SHAPE_FLOATS_PER_VERTEX);
        colorVertices = new Vector<Float>(numGlyphVertices * Almanac.COLOR_FLOATS_PER_VERTEX);
        paintVertices = new Vector<Float>(numGlyphVertices * Almanac.PAINT_FLOATS_PER_VERTEX);
        indices = new Vector<UInt>(numGlyphIndices);
    }

    inline function createGlyphs():Void {
        glyphs = [];
        for (ike in 0...numGlyphs) {
            var glyph:Glyph = new Glyph(ike, shapeVertices, colorVertices, paintVertices);
            glyphs.push(glyph);
        }
    }

    public function update():Void {
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

        for (srcGlyph in glyphsToToggle) {

            if (srcGlyph == null || srcGlyph.visible == visible) continue;

            var srcIndexAddress:Int = srcGlyph.indexAddress;
            if (glyphsByIndex[srcIndexAddress] != srcGlyph) continue;
            var dstIndexAddress:Int = numVisibleGlyphs + offset;

            srcGlyph.visible = visible;
            var dstGlyph:Glyph = glyphsByIndex[dstIndexAddress];

            if (srcGlyph != dstGlyph) {
                insertGlyph(dstGlyph, srcIndexAddress);
                insertGlyph(srcGlyph, dstIndexAddress);
            }

            numVisibleGlyphs += step;
            diff += step;
        }

        return diff;
    }

    inline function insertGlyph(glyph:Glyph, indexAddress:Int):Void {
        var firstVertIndex:Int = glyph.id * Almanac.VERTICES_PER_GLYPH;

        var vec:Vector<UInt> = new Vector<UInt>();
        vec.push(firstVertIndex + 0);
        vec.push(firstVertIndex + 1);
        vec.push(firstVertIndex + 2);
        vec.push(firstVertIndex + 0);
        vec.push(firstVertIndex + 2);
        vec.push(firstVertIndex + 3);

        writeArrayToVector(indices, indexAddress * Almanac.INDICES_PER_GLYPH, vec, Almanac.INDICES_PER_GLYPH);

        glyphsByIndex[indexAddress] = glyph;
        glyph.indexAddress = indexAddress;
    }

    inline function writeArrayToVector<T>(array:Vector<T>, startIndex:Int, items:Vector<T>, numItems:Int):Void {
        for (ike in 0...items.length) array[startIndex + ike] = items[ike];
    }
}
