package net.rezmason.hypertype.core;

import net.rezmason.gl.IndexBuffer;
import net.rezmason.gl.BufferUsage;
import net.rezmason.gl.GLTypes;
import net.rezmason.gl.VertexBuffer;
import net.rezmason.gl.GLSystem;

import net.rezmason.utils.santa.Present;

using net.rezmason.hypertype.core.GlyphUtils;

class BodySegment {

    public var id(default, null):Int;

    public var colorBuffer(default, null):VertexBuffer;
    public var geometryBuffer(default, null):VertexBuffer;
    public var paintBuffer(default, null):VertexBuffer;
    public var indexBuffer(default, null):IndexBuffer;

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
        upload();
    }

    inline function createBuffersAndVectors(numGlyphs:Int, glSys:GLSystem):Void {
        var numGlyphVertices:Int = numGlyphs * Almanac.VERTICES_PER_GLYPH;
        var numGlyphIndices:Int = numGlyphs * Almanac.INDICES_PER_GLYPH;
        var bufferUsage:BufferUsage = DYNAMIC_DRAW;

        geometryBuffer = glSys.createVertexBuffer(numGlyphVertices, Almanac.GEOMETRY_FLOATS_PER_VERTEX, bufferUsage);
        colorBuffer = glSys.createVertexBuffer(numGlyphVertices, Almanac.COLOR_FLOATS_PER_VERTEX, bufferUsage);
        paintBuffer = glSys.createVertexBuffer(numGlyphVertices, Almanac.PAINT_FLOATS_PER_VERTEX, bufferUsage);
        indexBuffer = glSys.createIndexBuffer(numGlyphIndices, bufferUsage);
    }

    inline function createGlyphs(numGlyphs:Int, donor:BodySegment):Void {
        _trueGlyphs = [];
        for (ike in 0...numGlyphs) {
            var glyph:Glyph = null;
            if (donor != null) glyph = donor._trueGlyphs[ike];
            if (glyph == null) glyph = new Glyph(ike);
            glyph.geometryBuf = geometryBuffer;
            glyph.colorBuf = colorBuffer;
            glyph.paintBuf = paintBuffer;
            glyph.init();
            _trueGlyphs.push(glyph);
        }

        var order:Array<UInt> = Almanac.VERT_ORDER;
        for (glyph in _trueGlyphs) {
            var indexAddress:Int = glyph.id * Almanac.INDICES_PER_GLYPH;
            var firstVertIndex:Int = glyph.id * Almanac.VERTICES_PER_GLYPH;
            for (ike in 0...order.length) indexBuffer.mod(indexAddress + ike, firstVertIndex + order[ike]);
        }
    }

    public inline function invalidate():Void {
        if (numGlyphs > 0) {
            geometryBuffer.invalidate();
            colorBuffer.invalidate();
            paintBuffer.invalidate();
            indexBuffer.invalidate();
        }
    }

    public inline function upload():Void {
        if (numGlyphs > 0) {
            geometryBuffer.upload();
            colorBuffer.upload();
            paintBuffer.upload();
            indexBuffer.upload();
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
        geometryBuffer.dispose();
        colorBuffer.dispose();
        paintBuffer.dispose();
        indexBuffer.dispose();

        colorBuffer = null;
        geometryBuffer = null;
        paintBuffer = null;
        indexBuffer = null;
        numGlyphs = -1;
        _trueGlyphs = null;
        _glyphs = null;
        id = -1;
    }
}
