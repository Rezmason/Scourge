package net.rezmason.hypertype.core;

import net.rezmason.gl.IndexBuffer;
import net.rezmason.gl.BufferUsage;
import net.rezmason.gl.VertexBuffer;

using net.rezmason.hypertype.core.GlyphUtils;

class GlyphBatch {

    public var colorBuffer(default, null):VertexBuffer;
    public var fontBuffer(default, null):VertexBuffer;
    public var geometryBuffer(default, null):VertexBuffer;
    public var hitboxBuffer(default, null):VertexBuffer;
    public var indexBuffer(default, null):IndexBuffer;
    public var size(default, set):UInt;
    public var capacity(default, null):UInt;
    public var glyphs(default, null):Array<Glyph>;
    var allGlyphs:Array<Glyph>;

    public function new(capacity:UInt, offset:UInt, donor:GlyphBatch = null):Void {
        this.capacity = capacity;
        var numGlyphVertices:UInt = capacity * Almanac.VERTICES_PER_GLYPH;
        geometryBuffer = new VertexBuffer(numGlyphVertices, Almanac.GEOMETRY_FLOATS_PER_VERTEX, DYNAMIC_DRAW);
        colorBuffer = new VertexBuffer(numGlyphVertices, Almanac.COLOR_FLOATS_PER_VERTEX, DYNAMIC_DRAW);
        fontBuffer = new VertexBuffer(numGlyphVertices, Almanac.FONT_FLOATS_PER_VERTEX, DYNAMIC_DRAW);
        hitboxBuffer = new VertexBuffer(numGlyphVertices, Almanac.HITBOX_FLOATS_PER_VERTEX, DYNAMIC_DRAW);
        var numGlyphIndices:UInt = capacity * Almanac.INDICES_PER_GLYPH;
        indexBuffer = new IndexBuffer(numGlyphIndices, DYNAMIC_DRAW);
        allGlyphs = [];
        var donorGlyphs = donor != null ? donor.allGlyphs : [];
        var indexAddress:UInt = 0;
        var firstVertIndex:UInt = 0;
        for (ike in allGlyphs.length...capacity) allGlyphs.push(new Glyph());
        for (ike in 0...capacity) {
            var glyph = allGlyphs[ike];
            glyph.id = ike + offset;
            glyph.geometryBuf = geometryBuffer;
            glyph.fontBuf = fontBuffer;
            glyph.colorBuf = colorBuffer;
            glyph.hitboxBuf = hitboxBuffer;
            glyph.init();
            if (donorGlyphs[ike] != null) glyph.COPY(donorGlyphs[ike]);
            var order:Array<UInt> = Almanac.VERT_ORDER;
            for (ike in 0...order.length) indexBuffer.mod(indexAddress + ike, firstVertIndex + order[ike]);
            indexAddress += Almanac.INDICES_PER_GLYPH;
            firstVertIndex += Almanac.VERTICES_PER_GLYPH;
        }
        set_size(capacity);
        if (donor != null) donor.destroy();
    }

    public inline function invalidate():Void {
        if (size > 0) {
            geometryBuffer.invalidate();
            fontBuffer.invalidate();
            colorBuffer.invalidate();
            hitboxBuffer.invalidate();
            indexBuffer.invalidate();
        }
    }

    public inline function upload():Void {
        if (size > 0) {
            geometryBuffer.upload();
            fontBuffer.upload();
            colorBuffer.upload();
            hitboxBuffer.upload();
            indexBuffer.upload();
        }
    }

    inline function set_size(val:UInt):UInt {
        if (size != val) {
            if (val < 0) throw 'Invalid GlyphBatch size $val.';
            if (val > capacity) throw "Glyph batches cannot expand beyond their capacity.";
            glyphs = allGlyphs.slice(0, val);
            if (size < val) for (ike in size...val) glyphs[ike].reset();
            size = val;
        }
        return val;
    }

    public function destroy():Void {
        size = 0;
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
        allGlyphs = null;
        glyphs = null;
        capacity = 0;
    }
}
