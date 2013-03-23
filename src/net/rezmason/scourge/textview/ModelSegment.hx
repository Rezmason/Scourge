package net.rezmason.scourge.textview;

import nme.display3D.Context3D;
import nme.display3D.IndexBuffer3D;
import nme.display3D.VertexBuffer3D;
import nme.Vector;

class ModelSegment {

    public var id:Int;

    public var colorBuffer:VertexBuffer3D;
    public var shapeBuffer:VertexBuffer3D;
    public var paintBuffer:VertexBuffer3D;
    public var indexBuffer:IndexBuffer3D;

    public var colorVertices:Vector<Float>;
    public var shapeVertices:Vector<Float>;
    public var paintVertices:Vector<Float>;
    public var indices:Vector<UInt>;

    public var startGlyph:Int;
    public var numGlyphs:Int;
    public var numVisibleGlyphs:Int;

    public var glyphs:Array<Glyph>;

    public function new(context:Context3D, segmentID:Int, glyphs:Array<Glyph>):Void {
        id = segmentID;
        this.glyphs = glyphs;
        numGlyphs = glyphs.length;
        numVisibleGlyphs = numGlyphs;

        if (numGlyphs == 0) return;

        createBuffers(context);
        createVectors();
        populateVectors();
        update();
    }

    inline function createBuffers(context:Context3D):Void {
        var numGlyphVertices:Int = numGlyphs * Almanac.NUM_VERTICES_PER_GLYPH;
        var numGlyphIndices:Int = numGlyphs * Almanac.NUM_INDICES_PER_GLYPH;

        shapeBuffer = context.createVertexBuffer(numGlyphVertices, Almanac.NUM_SHAPE_FLOATS_PER_VERTEX);
        colorBuffer = context.createVertexBuffer(numGlyphVertices, Almanac.NUM_COLOR_FLOATS_PER_VERTEX);
        paintBuffer = context.createVertexBuffer(numGlyphVertices, Almanac.NUM_PAINT_FLOATS_PER_VERTEX);
        indexBuffer = context.createIndexBuffer(numGlyphIndices);
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

            writeArrayToVector(shapeVertices, ike * Almanac.NUM_SHAPE_FLOATS_PER_GLYPH, glyph.shape, Almanac.NUM_SHAPE_FLOATS_PER_GLYPH);
            writeArrayToVector(colorVertices, ike * Almanac.NUM_COLOR_FLOATS_PER_GLYPH, glyph.color, Almanac.NUM_COLOR_FLOATS_PER_GLYPH);

            // TODO: Move to GlyphUtils.setID()

            var glyphID:Int = glyph.id + 1;
            var glyphR:Float = ((glyphID >> 16) & 0xFF) / 0xFF;
            var glyphG:Float = ((glyphID >>  8) & 0xFF) / 0xFF;
            var glyphB:Float = ((glyphID >>  0) & 0xFF) / 0xFF;

            writeArrayToVector(paintVertices, ike * Almanac.NUM_PAINT_FLOATS_PER_GLYPH, [
                glyphR, glyphG, glyphB,
                glyphR, glyphG, glyphB,
                glyphR, glyphG, glyphB,
                glyphR, glyphG, glyphB,
            ], Almanac.NUM_PAINT_FLOATS_PER_GLYPH);

            glyph.vertexAddress = ike;

            insertGlyph(glyph, ike);
        }
    }

    public function update():Void {
        if (numGlyphs > 0) {
            var numGlyphVertices:Int = numGlyphs * Almanac.NUM_VERTICES_PER_GLYPH;
            var numGlyphIndices:Int = numGlyphs * Almanac.NUM_INDICES_PER_GLYPH;
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
        var firstVertIndex:Int = glyph.vertexAddress * Almanac.NUM_VERTICES_PER_GLYPH;

        writeArrayToVector(indices, indexAddress * Almanac.NUM_INDICES_PER_GLYPH, [
            firstVertIndex + 0, firstVertIndex + 1, firstVertIndex + 2,
            firstVertIndex + 0, firstVertIndex + 2, firstVertIndex + 3,
        ], Almanac.NUM_INDICES_PER_GLYPH);

        glyphs[indexAddress] = glyph;
        glyph.indexAddress = indexAddress;
    }

    inline function writeArrayToVector<T>(array:Vector<T>, startIndex:Int, items:Array<T>, numItems:Int):Void {
        for (ike in 0...items.length) array[startIndex + ike] = items[ike];
    }
}
