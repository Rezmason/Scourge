package net.rezmason.scourge.textview.core;

import net.rezmason.gl.IndexBuffer;
import net.rezmason.gl.Types;
import net.rezmason.gl.VertexBuffer;
import net.rezmason.gl.utils.BufferUtil;

using net.rezmason.scourge.textview.core.GlyphUtils;

class BodySegment {

    public var id(default, null):Int;

    public var colorBuffer(default, null):VertexBuffer;
    public var shapeBuffer(default, null):VertexBuffer;
    public var paintBuffer(default, null):VertexBuffer;
    public var indexBuffer(default, null):IndexBuffer;

    public var colorVertices(default, null):VertexArray;
    public var shapeVertices(default, null):VertexArray;
    public var paintVertices(default, null):VertexArray;
    public var indices(default, null):IndexArray;

    public var numGlyphs(default, null):Int;
    public var glyphs(default, null):Array<Glyph>;

    public function new(bufferUtil:BufferUtil, segmentID:Int, numGlyphs:Int, donor:BodySegment = null):Void {
        if (numGlyphs < 0) numGlyphs = 0;
        id = segmentID;
        this.numGlyphs = numGlyphs;
        createBuffersAndVectors(bufferUtil);
        createGlyphs(donor);
        update();
    }

    inline function createBuffersAndVectors(bufferUtil:BufferUtil):Void {
        var numGlyphVertices:Int = numGlyphs * Almanac.VERTICES_PER_GLYPH;
        var numGlyphIndices:Int = numGlyphs * Almanac.INDICES_PER_GLYPH;

        shapeBuffer = bufferUtil.createVertexBuffer(numGlyphVertices, Almanac.SHAPE_FLOATS_PER_VERTEX);
        colorBuffer = bufferUtil.createVertexBuffer(numGlyphVertices, Almanac.COLOR_FLOATS_PER_VERTEX);
        paintBuffer = bufferUtil.createVertexBuffer(numGlyphVertices, Almanac.PAINT_FLOATS_PER_VERTEX);
        indexBuffer = bufferUtil.createIndexBuffer(numGlyphIndices);

        shapeVertices = new VertexArray(numGlyphVertices * Almanac.SHAPE_FLOATS_PER_VERTEX);
        colorVertices = new VertexArray(numGlyphVertices * Almanac.COLOR_FLOATS_PER_VERTEX);
        paintVertices = new VertexArray(numGlyphVertices * Almanac.PAINT_FLOATS_PER_VERTEX);
        indices = new IndexArray(numGlyphIndices);
    }

    inline function createGlyphs(donor:BodySegment):Void {
        glyphs = [];
        for (ike in 0...numGlyphs) {
            var glyph:Glyph = null;
            if (donor != null) {
                glyph = donor.glyphs[ike];
                glyph.transfer(shapeVertices, colorVertices, paintVertices);
            }

            if (glyph == null) glyph = new Glyph(ike, shapeVertices, colorVertices, paintVertices);
            glyphs.push(glyph);
        }

        var order:Array<UInt> = Almanac.VERT_ORDER;
        for (glyph in glyphs) {
            var indexAddress:Int = glyph.id * Almanac.INDICES_PER_GLYPH;
            var firstVertIndex:Int = glyph.id * Almanac.VERTICES_PER_GLYPH;
            for (ike in 0...order.length) indices[indexAddress + ike] = firstVertIndex + order[ike];
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

    public function destroy():Void {
        shapeBuffer.dispose();
        colorBuffer.dispose();
        paintBuffer.dispose();
        indexBuffer.dispose();

        colorVertices = null;
        shapeVertices = null;
        paintVertices = null;
        indices = null;
        glyphs = null;
        numGlyphs = -1;
        id = -1;
    }
}
