package net.rezmason.scourge.textview.core;

import net.rezmason.gl.IndexBuffer;
import net.rezmason.gl.BufferUsage;
import net.rezmason.gl.Data;
import net.rezmason.gl.VertexBuffer;
import net.rezmason.gl.GLSystem;

import net.rezmason.utils.santa.Present;

#if !flash
    import net.rezmason.gl.BufferUsage;
#end

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

    public var numGlyphs(default, set):Int;
    public var glyphs(get, null):Array<Glyph>;

    var _trueGlyphs:Array<Glyph>;
    var _glyphs:Array<Glyph>;

    public function new(segmentID:Int, numGlyphs:Int, donor:BodySegment = null):Void {
        if (numGlyphs < 0) numGlyphs = 0;
        id = segmentID;
        createBuffersAndVectors(numGlyphs, new Present(GLSystem));
        createGlyphs(numGlyphs, donor);
        this.numGlyphs = numGlyphs;
        update();
    }

    inline function createBuffersAndVectors(numGlyphs:Int, util:GLSystem):Void {
        var numGlyphVertices:Int = numGlyphs * Almanac.VERTICES_PER_GLYPH;
        var numGlyphIndices:Int = numGlyphs * Almanac.INDICES_PER_GLYPH;
        var bufferUsage:BufferUsage = DYNAMIC_DRAW;

        shapeBuffer = util.createVertexBuffer(numGlyphVertices, Almanac.SHAPE_FLOATS_PER_VERTEX, bufferUsage);
        colorBuffer = util.createVertexBuffer(numGlyphVertices, Almanac.COLOR_FLOATS_PER_VERTEX, bufferUsage);
        paintBuffer = util.createVertexBuffer(numGlyphVertices, Almanac.PAINT_FLOATS_PER_VERTEX, bufferUsage);
        indexBuffer = util.createIndexBuffer(numGlyphIndices, bufferUsage);

        shapeVertices = new VertexArray(numGlyphVertices * Almanac.SHAPE_FLOATS_PER_VERTEX);
        colorVertices = new VertexArray(numGlyphVertices * Almanac.COLOR_FLOATS_PER_VERTEX);
        paintVertices = new VertexArray(numGlyphVertices * Almanac.PAINT_FLOATS_PER_VERTEX);
        indices = new IndexArray(numGlyphIndices);
    }

    inline function createGlyphs(numGlyphs:Int, donor:BodySegment):Void {
        _trueGlyphs = [];
        for (ike in 0...numGlyphs) {
            var glyph:Glyph = null;
            if (donor != null) {
                glyph = donor._trueGlyphs[ike];
                if (glyph != null) {
                    glyph.transfer(shapeVertices, colorVertices, paintVertices);
                    glyph.reset();
                }
            }

            if (glyph == null) glyph = new Glyph(ike, shapeVertices, colorVertices, paintVertices);
            _trueGlyphs.push(glyph);
        }

        var order:Array<UInt> = Almanac.VERT_ORDER;
        for (glyph in _trueGlyphs) {
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

    inline function get_glyphs():Array<Glyph> return _glyphs;

    inline function set_numGlyphs(val:Int):Int {
        if (val < 0) val = 0;
        if (val > _trueGlyphs.length) throw "Body segments cannot expand beyond their initial size.";
        _glyphs = _trueGlyphs.slice(0, val);
        numGlyphs = val;
        return val;
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
        numGlyphs = -1;
        _trueGlyphs = null;
        _glyphs = null;
        id = -1;
    }
}
