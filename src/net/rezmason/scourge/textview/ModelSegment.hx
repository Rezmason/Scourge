package net.rezmason.scourge.textview;

import nme.display3D.IndexBuffer3D;
import nme.display3D.VertexBuffer3D;
import nme.Vector;

import net.rezmason.scourge.textview.utils.BufferUtil;

class ModelSegment {

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

    public function new(bufferUtil:BufferUtil, segmentID:Int, glyphs:Array<Glyph>):Void {
        id = segmentID;
        this.glyphs = glyphs;
        numGlyphs = glyphs.length;
        numVisibleGlyphs = numGlyphs;

        if (numGlyphs == 0) return;

        createBuffers(bufferUtil);
        createVectors();
        populateVectors();
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

    inline function populateVectors():Void {
        for (ike in 0...numGlyphs) {
            var glyph:Glyph = glyphs[ike];

            writeArrayToVector(shapeVertices, ike * Almanac.SHAPE_FLOATS_PER_GLYPH, glyph.shape, Almanac.SHAPE_FLOATS_PER_GLYPH);
            writeArrayToVector(colorVertices, ike * Almanac.COLOR_FLOATS_PER_GLYPH, glyph.color, Almanac.COLOR_FLOATS_PER_GLYPH);

            // TODO: Move to GlyphUtils.setID()

            var glyphID:Int = glyph.id + 1;
            var glyphR:Float = ((glyphID >> 16) & 0xFF) / 0xFF;
            var glyphG:Float = ((glyphID >>  8) & 0xFF) / 0xFF;
            var glyphB:Float = ((glyphID >>  0) & 0xFF) / 0xFF;

            writeArrayToVector(paintVertices, ike * Almanac.PAINT_FLOATS_PER_GLYPH, [
                glyphR, glyphG, glyphB,
                glyphR, glyphG, glyphB,
                glyphR, glyphG, glyphB,
                glyphR, glyphG, glyphB,
            ], Almanac.PAINT_FLOATS_PER_GLYPH);

            glyph.vertexAddress = ike;

            insertGlyph(glyph, ike);
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

    public function toggleGlyphs(_glyphs:Array<Glyph>, visible:Bool):Int {

        var step:Int = visible ? 1 : -1;
        var offset:Int = visible ? 0 : -1;
        var diff:Int = 0;

        for (srcGlyph in _glyphs) {
            srcGlyph.visible = visible;

            var dstGlyph:Glyph = glyphs[numVisibleGlyphs + offset];

            var srcIndexAddress:Int = srcGlyph.indexAddress;
            var dstIndexAddress:Int = dstGlyph.indexAddress;

            insertGlyph(dstGlyph, srcIndexAddress);
            insertGlyph(srcGlyph, dstIndexAddress);
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

        glyphs[indexAddress] = glyph;
        glyph.indexAddress = indexAddress;
    }

    inline function writeArrayToVector<T>(array:Vector<T>, startIndex:Int, items:Array<T>, numItems:Int):Void {
        for (ike in 0...items.length) array[startIndex + ike] = items[ike];
    }
}
