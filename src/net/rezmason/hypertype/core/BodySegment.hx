package net.rezmason.hypertype.core;

import net.rezmason.gl.IndexBuffer;
import net.rezmason.gl.BufferUsage;
import net.rezmason.gl.VertexBuffer;

using net.rezmason.hypertype.core.GlyphUtils;

class BodySegment {

    public var id(default, null):Int;

    public var colorBuffer(default, null):VertexBuffer;
    public var fontBuffer(default, null):VertexBuffer;
    public var geometryBuffer(default, null):VertexBuffer;
    public var hitboxBuffer(default, null):VertexBuffer;
    public var indexBuffer(default, null):IndexBuffer;

    public var numGlyphs(default, set):Int;
    public var glyphs(get, null):Array<Glyph>;

    var _trueGlyphs:Array<Glyph>;
    var _glyphs:Array<Glyph>;

    public function new(segmentID:Int, numGlyphs:Int, donor:BodySegment = null):Void {
        if (numGlyphs < 0) numGlyphs = 0;
        id = segmentID;
        createBuffersAndVectors(numGlyphs);
        createGlyphs(numGlyphs, donor);
        this.numGlyphs = numGlyphs;
        upload();
    }

    inline function createBuffersAndVectors(numGlyphs:Int):Void {
        var numGlyphVertices:Int = numGlyphs * Almanac.VERTICES_PER_GLYPH;
        var numGlyphIndices:Int = numGlyphs * Almanac.INDICES_PER_GLYPH;
        var bufferUsage:BufferUsage = DYNAMIC_DRAW;

        geometryBuffer = new VertexBuffer(numGlyphVertices, Almanac.GEOMETRY_FLOATS_PER_VERTEX, bufferUsage);
        colorBuffer = new VertexBuffer(numGlyphVertices, Almanac.COLOR_FLOATS_PER_VERTEX, bufferUsage);
        fontBuffer = new VertexBuffer(numGlyphVertices, Almanac.FONT_FLOATS_PER_VERTEX, bufferUsage);
        hitboxBuffer = new VertexBuffer(numGlyphVertices, Almanac.HITBOX_FLOATS_PER_VERTEX, bufferUsage);
        indexBuffer = new IndexBuffer(numGlyphIndices, bufferUsage);
    }

    inline function createGlyphs(numGlyphs:Int, donor:BodySegment):Void {
        _trueGlyphs = [];
        for (ike in 0...numGlyphs) {
            var glyph:Glyph = null;
            if (donor != null) glyph = donor._trueGlyphs[ike];
            if (glyph == null) glyph = new Glyph(ike);
            glyph.geometryBuf = geometryBuffer;
            glyph.fontBuf = fontBuffer;
            glyph.colorBuf = colorBuffer;
            glyph.hitboxBuf = hitboxBuffer;
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
            fontBuffer.invalidate();
            colorBuffer.invalidate();
            hitboxBuffer.invalidate();
            indexBuffer.invalidate();
        }
    }

    public inline function upload():Void {
        if (numGlyphs > 0) {
            geometryBuffer.upload();
            fontBuffer.upload();
            colorBuffer.upload();
            hitboxBuffer.upload();
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
        fontBuffer.dispose();
        colorBuffer.dispose();
        hitboxBuffer.dispose();
        indexBuffer.dispose();

        fontBuffer = null;
        colorBuffer = null;
        geometryBuffer = null;
        hitboxBuffer = null;
        indexBuffer = null;
        numGlyphs = -1;
        _trueGlyphs = null;
        _glyphs = null;
        id = -1;
    }
}
