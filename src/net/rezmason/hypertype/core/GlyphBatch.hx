package net.rezmason.hypertype.core;

import net.rezmason.gl.IndexBuffer;
import net.rezmason.gl.BufferUsage;
import net.rezmason.gl.VertexBuffer;

using net.rezmason.hypertype.core.GlyphUtils;

class GlyphBatch {

    public var id(default, null):Int;

    public var colorBuffer(default, null):VertexBuffer;
    public var fontBuffer(default, null):VertexBuffer;
    public var geometryBuffer(default, null):VertexBuffer;
    public var hitboxBuffer(default, null):VertexBuffer;
    public var indexBuffer(default, null):IndexBuffer;

    public var numGlyphs(default, set):Int;
    public var glyphs(default, null):Array<Glyph>;

    var trueGlyphs:Array<Glyph>;

    public function new(id:Int, numGlyphs:Int, donor:GlyphBatch = null):Void {
        if (numGlyphs < 0) numGlyphs = 0;
        this.id = id;
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

    inline function createGlyphs(numGlyphs:Int, donor:GlyphBatch):Void {
        trueGlyphs = [];
        for (ike in 0...numGlyphs) {
            var glyph:Glyph = null;
            if (donor != null) glyph = donor.trueGlyphs[ike];
            if (glyph == null) glyph = new Glyph(ike);
            glyph.geometryBuf = geometryBuffer;
            glyph.fontBuf = fontBuffer;
            glyph.colorBuf = colorBuffer;
            glyph.hitboxBuf = hitboxBuffer;
            glyph.init();
            trueGlyphs.push(glyph);
        }
        if (donor != null) donor.destroy();
        
        var order:Array<UInt> = Almanac.VERT_ORDER;
        for (glyph in trueGlyphs) {
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

    inline function set_numGlyphs(val:Int):Int {
        if (val < 0) val = 0;
        if (val > trueGlyphs.length) throw "Glyph batches cannot expand beyond their initial size.";
        glyphs = trueGlyphs.slice(0, val);
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
        trueGlyphs = null;
        glyphs = null;
        id = -1;
    }
}
