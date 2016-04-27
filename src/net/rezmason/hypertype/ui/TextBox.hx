package net.rezmason.hypertype.ui;

import net.rezmason.math.Vec4;
import net.rezmason.hypertype.Strings.*;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Glyph;
import net.rezmason.hypertype.text.ParagraphAlign; // TODO: move to UI

using net.rezmason.hypertype.core.GlyphUtils;
using net.rezmason.utils.CharCode;

class TextBox {

    public var body(default, null):Body = new Body();
    public var color(default, set):Vec4 = new Vec4(1, 1, 1);
    public var width(default, set):Float = 0;
    public var height(default, set):Float = 0;
    public var glyphWidth(default, set):Float = 0.1;
    var redrawDeferred = false;
    public var text(default, set):String = null;
    public var align(default, set):ParagraphAlign = LEFT;
    
    public function new() body.sceneSetSignal.add(redraw);

    public function redraw() {
        if (body.scene == null) return;
        body.glyphScale = glyphWidth * body.scene.camera.rect.width / body.font.glyphRatio;
        var numGlyphsWide = Std.int(Math.ceil(width / glyphWidth));
        var numGlyphsHigh = Std.int(Math.ceil(height / glyphWidth));

        // TODO: layout
        // TODO: string

        for (glyph in body.eachGlyph()) glyph.set_color(color);
    }
    
    inline function set_color(color) return this.color = color;
    inline function set_width(width:Float) return this.width = (width < 0 || Math.isNaN(width)) ? 0 : width;
    inline function set_height(height:Float) return this.height = (height < 0 || Math.isNaN(height)) ? 0 : height;
    inline function set_glyphWidth(glyphWidth:Float) return this.glyphWidth = (glyphWidth < 0 || Math.isNaN(glyphWidth)) ? 0 : glyphWidth;
    inline function set_text(text) return this.text = text;
    inline function set_align(align) return this.align = align;
}
