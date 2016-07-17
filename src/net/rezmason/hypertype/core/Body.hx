package net.rezmason.hypertype.core;

import lime.math.Matrix4;
import lime.math.Vector4;
import net.rezmason.ds.SceneNode;
import net.rezmason.hypertype.core.Almanac.*;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

using net.rezmason.hypertype.core.GlyphUtils;

class Body extends Container {

    public var size(default, set):UInt = 0;
    public var capacity(default, null):UInt = 0;
    public var interactiveID(default, set):UInt;
    public var font(default, set):GlyphFont;
    
    @:allow(net.rezmason.hypertype.core) var glyphBatches(default, null):Array<GlyphBatch> = [];
    
    var growRate:Float;
    var glyphs:Array<Glyph> = [];

    public function new(growRate = 1.5):Void {
        super();
        this.growRate = growRate;
        var fontManager:FontManager = new Present(FontManager);
        fontManager.onFontChange.add(updateFont);
        font = fontManager.defaultFont;
    }

    public inline function getGlyphByID(id:Int):Glyph return glyphs[id];

    public inline function eachGlyph():Iterator<Glyph> return glyphs.iterator();

    public function set_size(val:UInt) {
        if (size != val) {
            if (capacity < val) {
                capacity = val;
                var remainingCapacity = val;
                var batchIndex = 0;
                var offset = 0;
                var oldGlyphBatches = glyphBatches;
                glyphBatches = [];
                while (remainingCapacity > 0) {
                    var batchCapacity = remainingCapacity < BUFFER_CHUNK ? remainingCapacity : BUFFER_CHUNK;
                    var batch = oldGlyphBatches[batchIndex];
                    if (batch == null) batch = new GlyphBatch(batchCapacity, offset);
                    else if (batch.capacity < batchCapacity) batch = new GlyphBatch(batchCapacity, offset, batch);
                    glyphBatches.push(batch);
                    remainingCapacity -= batch.capacity;
                    offset += batch.capacity;
                    batchIndex++;
                }
            } else {
                var remainingSize = val;
                var batchIndex = 0;
                while (remainingSize > 0) {
                    var batch = glyphBatches[batchIndex];
                    batch.size = remainingSize < batch.capacity ? remainingSize : batch.capacity;
                    remainingSize -= batch.size;
                    batchIndex++;
                }
            }

            glyphs = [];
            for (batch in glyphBatches) glyphs = glyphs.concat(batch.glyphs);
            for (glyph in glyphs) glyph.set_font(font);
            size = val;
        }
        
        return val;
    }

    @:allow(net.rezmason.hypertype.core)
    function upload():Void for (batch in glyphBatches) batch.upload();

    function updateFont(font:GlyphFont):Void {
        if (this.font != font) {
            this.font = font;
            params.x = glyphScale;
            for (glyph in glyphs) glyph.set_font(font);
        }
    }

    inline function set_font(font:GlyphFont) {
        if (font != null) this.font = font;
        return this.font;
    }

    inline function set_interactiveID(interactiveID:UInt) {
        this.interactiveID = interactiveID;
        params.y = interactiveID / 0xFF;
        return this.interactiveID;
    }
}
