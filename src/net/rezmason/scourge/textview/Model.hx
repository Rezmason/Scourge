package net.rezmason.scourge.textview;

import nme.display3D.Context3D;
import nme.display3D.textures.Texture;
import nme.display3D.IndexBuffer3D;
import nme.display3D.VertexBuffer3D;
import nme.geom.Matrix3D;
import nme.geom.Rectangle;
import nme.Vector;

import net.rezmason.utils.FlatFont;

class Model {
    public var segments:Array<BufferSegment>;
    public var id:Int;
    public var matrix:Matrix3D;
    public var numGlyphs:Int;
    public var numVisibleGlyphs:Int;
    public var texture:Texture;
    public var scissorRectangle:Rectangle;
    var glyphTexture:GlyphTexture;

    public var glyphs:Array<Glyph>;

    var font:FlatFont;

    var context:Context3D;

    public function new(id:Int, context:Context3D, font:FlatFont):Void {
        this.id = id;
        this.context = context;
        this.font = font;

        glyphTexture = new GlyphTexture(context, font.getBitmapDataClone());
        texture = glyphTexture.texture;
        makeGlyphs();
        numGlyphs = glyphs.length;
        numVisibleGlyphs = glyphs.length;
        makeSegments();

        matrix = new Matrix3D();
        scissorRectangle = new Rectangle();
    }

    function makeGlyphs():Void {
        glyphs = [];
    }

    function makeSegments():Void {

        segments = [];

        var remainingGlyphs:Int = glyphs.length;
        var startGlyph:Int = 0;

        var segmentId:Int = 0;
        while (startGlyph < Constants.NUM_CHARS) {
            var len:Int = Std.int(Math.min(remainingGlyphs, Almanac.CHAR_QUAD_CHUNK));
            segments.push(makeSegment(segmentId, startGlyph, len));

            startGlyph += Almanac.CHAR_QUAD_CHUNK;
            remainingGlyphs -= Almanac.CHAR_QUAD_CHUNK;
            segmentId++;
        }
    }

    function makeSegment(segmentId:Int, startGlyph:Int, numGlyphs:Int):BufferSegment {

        var segment:BufferSegment = new BufferSegment();
        segment.id = segmentId;
        segment.numGlyphs = numGlyphs;

        if (numGlyphs > 0) {
            var numGlyphVertices:Int = numGlyphs * Almanac.NUM_VERTICES_PER_QUAD;
            var numGlyphIndices:Int = numGlyphs * Almanac.NUM_INDICES_PER_QUAD;

            var geomBuffer:VertexBuffer3D = context.createVertexBuffer(numGlyphVertices, Almanac.NUM_GEOM_FLOATS_PER_VERTEX);
            var colorBuffer:VertexBuffer3D = context.createVertexBuffer(numGlyphVertices, Almanac.NUM_COLOR_FLOATS_PER_VERTEX);
            var idBuffer:VertexBuffer3D = context.createVertexBuffer(numGlyphVertices, Almanac.NUM_ID_FLOATS_PER_VERTEX);
            var indexBuffer:IndexBuffer3D = context.createIndexBuffer(numGlyphIndices);

            var geomVertices:Vector<Float> = new Vector<Float>();
            var colorVertices:Vector<Float> = new Vector<Float>();
            var idVertices:Vector<Float> = new Vector<Float>();
            var indices:Vector<UInt> = new Vector<UInt>();

            for (itr in 0...numGlyphs) {

                var glyphIndex:Int = itr + startGlyph;

                var glyph:Glyph = glyphs[glyphIndex];

                writeArrayToVector(geomVertices, itr * Almanac.NUM_GEOM_FLOATS_PER_QUAD, glyph.geom, Almanac.NUM_GEOM_FLOATS_PER_QUAD);
                writeArrayToVector(colorVertices, itr * Almanac.NUM_COLOR_FLOATS_PER_QUAD, glyph.color, Almanac.NUM_COLOR_FLOATS_PER_QUAD);

                var glyphID:Int = glyph.id + 1;
                var glyphR:Float = ((glyphID >> 16) & 0xFF) / 0xFF;
                var glyphG:Float = ((glyphID >>  8) & 0xFF) / 0xFF;
                var glyphB:Float = ((glyphID >>  0) & 0xFF) / 0xFF;

                writeArrayToVector(idVertices, itr * Almanac.NUM_ID_FLOATS_PER_QUAD, [
                    glyphR, glyphG, glyphB,
                    glyphR, glyphG, glyphB,
                    glyphR, glyphG, glyphB,
                    glyphR, glyphG, glyphB,
                ], Almanac.NUM_ID_FLOATS_PER_QUAD);

                insertGlyph(indices, itr, itr);

                //glyph.renderIndex = itr;
                //glyph.renderSegmentIndex = segmentId;
            }

            segment.colorBuffer = colorBuffer;
            segment.geomBuffer = geomBuffer;
            segment.idBuffer = idBuffer;
            segment.indexBuffer = indexBuffer;

            segment.colorVertices = colorVertices;
            segment.geomVertices = geomVertices;
            segment.idVertices = idVertices;
            segment.indices = indices;

            updateSegment(segment);
        }

        return segment;
    }

    public function toggleGlyphs(_glyphs:Array<Glyph>, visible:Bool):Void {

        var glyphsToChange:Array<Glyph> = [];
        var glyphIDsToChange:IntHash<Bool> = new IntHash<Bool>();
        for (glyph in _glyphs) {
            if (glyph != null && glyph.visible == !visible && !glyphIDsToChange.exists(glyph.id)) {
                glyphsToChange.push(glyph);
                glyphIDsToChange.set(glyph.id, true);
            }
        }

        var invalidSegments:Array<Bool> = [];

        var step:Int = visible ? 1 : -1;
        var offset:Int = visible ? 0 : -1;

        for (srcGlyph in glyphsToChange) {

            var dstGlyph:Glyph = glyphs[numVisibleGlyphs + offset];

            var srcIndex:Int = srcGlyph.index;
            var srcSegmentIndex:Int = Std.int(srcIndex / Almanac.CHAR_QUAD_CHUNK);
            var srcSegment:BufferSegment = segments[srcSegmentIndex];
            var srcRenderIndex:Int = srcIndex % Almanac.CHAR_QUAD_CHUNK;

            var dstIndex:Int = dstGlyph.index;
            var dstSegmentIndex:Int = Std.int(dstIndex / Almanac.CHAR_QUAD_CHUNK);
            var dstSegment:BufferSegment = segments[dstSegmentIndex];
            var dstRenderIndex:Int = dstIndex % Almanac.CHAR_QUAD_CHUNK;

            //swapBetweenVectors(srcSegment.indices, dstSegment.indices, srcRenderIndex * Almanac.NUM_INDICES_PER_QUAD, dstRenderIndex * Almanac.NUM_INDICES_PER_QUAD, Almanac.NUM_INDICES_PER_QUAD);
            insertGlyph(srcSegment.indices, dstGlyph.id, srcRenderIndex);
            insertGlyph(dstSegment.indices, srcGlyph.id, dstRenderIndex);

            srcGlyph.index = dstIndex;
            dstGlyph.index = srcIndex;
            glyphs[dstIndex] = srcGlyph;
            glyphs[srcIndex] = dstGlyph;

            srcGlyph.visible = visible;

            invalidSegments[srcSegmentIndex] = true;
            invalidSegments[dstSegmentIndex] = true;

            numVisibleGlyphs += step;
        }

        for (ike in 0...invalidSegments.length) {
            if (invalidSegments[ike]) {
                updateSegment(segments[ike]);
            }
        }
    }

    inline function updateSegment(segment:BufferSegment):Void {

        if (segment.numGlyphs > 0) {
            // EXPENSIVE! Use a flag system to indicate what's invalid in a segment

            var numGlyphVertices:Int = segment.numGlyphs * Almanac.NUM_VERTICES_PER_QUAD;
            var numGlyphIndices:Int = segment.numGlyphs * Almanac.NUM_INDICES_PER_QUAD;

            segment.geomBuffer.uploadFromVector(segment.geomVertices, 0, numGlyphVertices);
            segment.colorBuffer.uploadFromVector(segment.colorVertices, 0, numGlyphVertices);
            segment.idBuffer.uploadFromVector(segment.idVertices, 0, numGlyphVertices);
            segment.indexBuffer.uploadFromVector(segment.indices, 0, numGlyphIndices);
        }
    }

    inline function insertGlyph(indices:Vector<UInt>, glyphIndex:Int, addressIndex:Int):Void {
        var firstIndex:Int = glyphIndex * Almanac.NUM_VERTICES_PER_QUAD;

        writeArrayToVector(indices, addressIndex * Almanac.NUM_INDICES_PER_QUAD, [
            firstIndex + 0, firstIndex + 1, firstIndex + 2,
            firstIndex + 0, firstIndex + 2, firstIndex + 3,
        ], Almanac.NUM_INDICES_PER_QUAD);
    }

    inline function writeArrayToVector<T>(array:Vector<T>, startIndex:Int, items:Array<T>, numItems:Int):Void {
        for (ike in 0...items.length) array[startIndex + ike] = items[ike];
    }

    inline function swapBetweenVectors<T>(src:Vector<T>, dst:Vector<T>, srcRenderIndex:Int, dstRenderIndex:Int, numItems:Int):Void {
        for (ike in 0...numItems) {
            var srcVal:T = src[srcRenderIndex + ike];
            src[srcRenderIndex + ike] = dst[dstRenderIndex + ike];
            dst[dstRenderIndex + ike] = srcVal;
        }
    }
}
