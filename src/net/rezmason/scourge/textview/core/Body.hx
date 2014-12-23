package net.rezmason.scourge.textview.core;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;

import net.rezmason.ds.SceneNode;
import net.rezmason.utils.Zig;
import net.rezmason.utils.santa.Present;

using net.rezmason.scourge.textview.core.GlyphUtils;

class Body extends SceneNode<Body> {

    static var _ids:Int = 0;

    public var numGlyphs(default, null):Int;
    public var id(default, null):Int;
    public var transform(default, null):Matrix3D;
    public var concatenatedTransform(get, null):Matrix3D;
    public var glyphScale(default, set):Float;
    public var glyphTexture(default, set):GlyphTexture;
    public var scene(default, null):Scene;
    
    public var fontChangedSignal(default, null):Zig<Void->Void>;
    public var interactionSignal(default, null):Zig<Int->Interaction->Void>;
    public var updateSignal(default, null):Zig<Float->Void>;

    @:allow(net.rezmason.scourge.textview.core) var segments(default, null):Array<BodySegment>;
    @:allow(net.rezmason.scourge.textview.core) var params(default, null):Array<Float>;
    
    var trueNumGlyphs:Int;
    var concatMat:Matrix3D;
    var glyphs:Array<Glyph>;

    public function new():Void {
        super();
        fontChangedSignal = new Zig();
        interactionSignal = new Zig();
        updateSignal = new Zig();
        id = ++_ids;
        glyphs = [];
        var fontManager:FontManager = new Present(FontManager);
        fontManager.onFontChange.add(updateGlyphTexture);
        glyphTexture = fontManager.defaultFont;

        numGlyphs = 0;
        trueNumGlyphs = 0;

        segments = [];
        glyphs = [];

        transform = new Matrix3D();
        concatMat = new Matrix3D();
        params = [0, 0, 0, 0];
        params[2] = id / 0xFF;
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

    public function growTo(numGlyphs:Int):Void {
        if (trueNumGlyphs < numGlyphs) {

            var oldSegments:Array<BodySegment> = segments;
            var oldGlyphs:Array<Glyph> = glyphs;

            glyphs = [];
            segments = [];

            var remainingGlyphs:Int = numGlyphs;
            var startGlyph:Int = 0;
            var segmentID:Int = 0;

            while (startGlyph < numGlyphs) {
                var len:Int = Std.int(Math.min(remainingGlyphs, Almanac.BUFFER_CHUNK));
                var segment:BodySegment = null;
                var donor:BodySegment = oldSegments[segmentID];

                if (donor != null && donor.numGlyphs == len) {
                    segment = donor;
                    segment.numGlyphs = len;
                } else {
                    segment = new BodySegment(segmentID, len, donor);
                    if (donor != null) donor.destroy();
                }

                segments.push(segment);
                glyphs = glyphs.concat(segment.glyphs);
                startGlyph += Almanac.BUFFER_CHUNK;
                remainingGlyphs -= Almanac.BUFFER_CHUNK;
                segmentID++;
            }

            trueNumGlyphs = numGlyphs;

        } else {
            var remainingGlyphs:Int = numGlyphs;
            for (segment in segments) {
                segment.numGlyphs = Std.int(Math.min(remainingGlyphs, Almanac.BUFFER_CHUNK));
                remainingGlyphs -= Almanac.BUFFER_CHUNK;
            }
        }
        this.numGlyphs = numGlyphs;
        for (glyph in glyphs) glyph.set_font(glyphTexture.font);
    }

    @:allow(net.rezmason.scourge.textview.core)
    function update(delta:Float):Void {
        updateSignal.dispatch(delta);
        if (scene != null) for (segment in segments) segment.update();
    }

    @:allow(net.rezmason.scourge.textview.core)
    function setScene(scene:Scene):Void {
        var lastScene:Scene = this.scene;
        if (this.scene != null) this.scene.resizeSignal.remove(updateGlyphTransform);
        this.scene = scene;
        updateGlyphTransform();
        if (this.scene != null) this.scene.resizeSignal.add(updateGlyphTransform);
        if (lastScene == null) for (segment in segments) segment.update();
        for (child in children()) child.setScene(scene);
    }

    function updateGlyphTexture(glyphTexture:GlyphTexture):Void {
        if (this.glyphTexture != glyphTexture) {
            this.glyphTexture = glyphTexture;
            updateGlyphTransform();
            for (glyph in glyphs) glyph.set_font(glyphTexture.font);
        }
    }

    inline function set_glyphScale(val:Float):Float {
        glyphScale = val;
        updateGlyphTransform();
        return glyphScale;
    }

    inline function set_glyphTexture(tex:GlyphTexture):GlyphTexture {
        if (tex != null) {
            this.glyphTexture = tex;
            fontChangedSignal.dispatch();
        }
        return glyphTexture;
    }

    inline function updateGlyphTransform():Void {
        if (glyphTexture != null && scene != null) {
            params[0] = glyphScale * scene.camera.glyphScale;
            params[1] = glyphScale * scene.camera.glyphScale * scene.stageWidth / scene.stageHeight * glyphTexture.font.glyphRatio;
        }
    }

    function get_concatenatedTransform():Matrix3D {
        concatMat.copyFrom(transform);
        if (parent != null) concatMat.append(parent.concatenatedTransform);
        return concatMat;
    }
}
