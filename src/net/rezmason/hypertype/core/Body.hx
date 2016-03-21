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
    public var font(default, set):GlyphFont;
    public var scene(default, null):Scene;
    public var mouseEnabled:Bool = true;
    public var visible:Bool = true;
    
    public var fontChangedSignal(default, null):Zig<Void->Void> = new Zig();
    public var interactionSignal(default, null):Zig<Int->Interaction->Void> = new Zig();
    public var updateSignal(default, null):Zig<Float->Void> = new Zig();
    public var sceneSetSignal(default, null):Zig<Void->Void> = new Zig();
    public var drawSignal(default, null):Zig<Void->Void> = new Zig();

    @:allow(net.rezmason.hypertype.core) var glyphBatches(default, null):Array<GlyphBatch> = [];
    @:allow(net.rezmason.hypertype.core) var params(default, null):Vector4;
    
    var growRate:Float;
    var concatMat:Matrix4 = new Matrix4();
    var glyphs:Array<Glyph> = [];

    public function new(growRate = 1.5):Void {
        super();
        this.growRate = growRate;
        var fontManager:FontManager = new Present(FontManager);
        fontManager.onFontChange.add(updateFont);
        font = fontManager.defaultFont;
        params = new Vector4();
        params.z = id / 0xFF;
        glyphScale = 1;
    }

    override public function addChild(node:Body):Bool {
        var success = super.addChild(node);
        if (success) {
            node.setScene(scene);
            node.update(0);
            if (scene != null) scene.invalidate();
        }
        return success;
    }

    override public function removeChild(node:Body):Bool {
        var success = super.removeChild(node);
        if (success) {
            node.setScene(null);
            if (scene != null) scene.invalidate();
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
    function upload():Void for (batch in glyphBatches) batch.upload();

    @:allow(net.rezmason.hypertype.core)
    function setScene(scene:Scene):Void {
        var lastScene:Scene = this.scene;
        if (this.scene != null) this.scene.resizeSignal.remove(updateGlyphTransform);
        this.scene = scene;
        updateGlyphTransform();
        if (this.scene != null) this.scene.resizeSignal.add(updateGlyphTransform);
        for (child in children()) child.setScene(scene);
        sceneSetSignal.dispatch();
    }

    function updateFont(font:GlyphFont):Void {
        if (this.font != font) {
            this.font = font;
            updateGlyphTransform();
            for (glyph in glyphs) glyph.set_font(font);
        }
    }

    inline function set_glyphScale(val:Float):Float {
        glyphScale = val;
        updateGlyphTransform();
        return glyphScale;
    }

    inline function set_font(font:GlyphFont) {
        if (font != null) {
            this.font = font;
            fontChangedSignal.dispatch();
        }
        return this.font;
    }

    inline function updateGlyphTransform():Void {
        if (scene != null) {
            params.x = glyphScale * scene.camera.glyphScale;
            params.y = glyphScale * scene.camera.glyphScale * scene.stageWidth / scene.stageHeight;
        }
    }

    function get_concatenatedTransform():Matrix4 {
        concatMat.copyFrom(transform);
        if (parent != null) concatMat.append(parent.concatenatedTransform);
        return concatMat;
    }
}
