package net.rezmason.hypertype.core;

import lime.math.Matrix4;
import lime.math.Vector4;
import net.rezmason.ds.SceneNode;
import net.rezmason.hypertype.core.Almanac.*;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

using net.rezmason.hypertype.core.GlyphUtils;

class Body extends SceneNode<Body> {

    static var _ids:Int = 0;

    public var size(default, set):UInt = 0;
    public var capacity(default, null):UInt = 0;
    public var id(default, null):Int = ++_ids;
    public var transform(default, null):Matrix4 = new Matrix4();
    public var concatenatedTransform(get, null):Matrix4;
    public var glyphScale(default, set):Float;
    public var concatenatedParams(get, null):Vector4;
    public var font(default, set):GlyphFont;
    public var mouseEnabled(default, set):Bool = true;
    public var visible(default, set):Bool = true;
    public var isInteractive(get, null):Bool;
    public var interactionSignal(default, null):Zig<Int->Interaction->Void> = new Zig();
    public var updateSignal(default, null):Zig<Float->Void> = new Zig();
    public var invalidateSignal(default, null):Zig<Void->Void> = new Zig();

    @:allow(net.rezmason.hypertype.core) var glyphBatches(default, null):Array<GlyphBatch> = [];
    
    var growRate:Float;
    var concatTransform:Matrix4 = new Matrix4();
    var params:Vector4;
    var concatParams:Vector4 = new Vector4();
    var glyphs:Array<Glyph> = [];

    public function new(growRate = 1.5):Void {
        super();
        this.growRate = growRate;
        var fontManager:FontManager = new Present(FontManager);
        fontManager.onFontChange.add(updateFont);
        font = fontManager.defaultFont;
        params = new Vector4();
        glyphScale = 1;
        params.x = glyphScale;
        params.y = id / 0xFF;
    }

    override public function addChild(node:Body):Bool {
        var success = super.addChild(node);
        if (success) {
            node.update(0);
            node.invalidateSignal.add(invalidateSignal.dispatch);
            invalidateSignal.dispatch();
        }
        return success;
    }

    override public function removeChild(node:Body):Bool {
        var success = super.removeChild(node);
        if (success) {
            node.invalidateSignal.remove(invalidateSignal.dispatch);
            invalidateSignal.dispatch();
        }
        return success;
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
    function update(delta:Float):Void updateSignal.dispatch(delta);

    @:allow(net.rezmason.hypertype.core)
    function interact(glyphID:Int, interaction:Interaction):Void interactionSignal.dispatch(glyphID, interaction);

    @:allow(net.rezmason.hypertype.core)
    function upload():Void for (batch in glyphBatches) batch.upload();

    function updateFont(font:GlyphFont):Void {
        if (this.font != font) {
            this.font = font;
            params.x = glyphScale;
            for (glyph in glyphs) glyph.set_font(font);
        }
    }

    inline function set_glyphScale(val:Float):Float {
        glyphScale = val;
        params.x = glyphScale;
        return glyphScale;
    }

    inline function set_font(font:GlyphFont) {
        if (font != null) this.font = font;
        return this.font;
    }

    inline function set_visible(visible:Bool) {
        var isInteractive = this.isInteractive;
        this.visible = visible;
        if (isInteractive != this.isInteractive) invalidateSignal.dispatch();
        return this.visible;
    }

    inline function set_mouseEnabled(mouseEnabled:Bool) {
        var isInteractive = this.isInteractive;
        this.mouseEnabled = mouseEnabled;
        if (isInteractive != this.isInteractive) invalidateSignal.dispatch();
        return this.mouseEnabled;
    }

    inline function get_isInteractive() return visible && mouseEnabled;

    function get_concatenatedTransform():Matrix4 {
        concatTransform.copyFrom(transform);
        if (parent != null) concatTransform.append(parent.concatenatedTransform);
        return concatTransform;
    }

    function get_concatenatedParams():Vector4 {
        concatParams.copyFrom(params);
        if (parent != null) {
            var parentParams = parent.concatenatedParams;
            concatParams.x *= parentParams.x;
            concatParams.y *= parentParams.y;
            concatParams.z *= parentParams.z;
            concatParams.w *= parentParams.w;
        }
        return concatParams;
    }
}
