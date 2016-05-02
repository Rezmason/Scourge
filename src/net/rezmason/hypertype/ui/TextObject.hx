package net.rezmason.hypertype.ui;

import haxe.Utf8;
import net.rezmason.math.Vec4;
import net.rezmason.hypertype.Strings.*;
import net.rezmason.hypertype.core.Body;
import net.rezmason.hypertype.core.Glyph;
import net.rezmason.hypertype.text.ParagraphAlign; // TODO: move to UI
import net.rezmason.hypertype.text.VerticalAlign; // TODO: move to UI

using net.rezmason.hypertype.core.GlyphUtils;
using net.rezmason.utils.CharCode;

class TextObject {

    var numRequiredGlyphs:UInt;

    public var body(default, null):Body = new Body();
    public var color:Vec4 = new Vec4(1, 1, 1);
    public var glyphWidth:Float = 0.1;
    public var text:String = null;
    public var align:ParagraphAlign = LEFT;
    public var verticalAlign:VerticalAlign = TOP;
    var glyphHeight:Float;
    
    public function new() body.sceneSetSignal.add(redraw);

    public function redraw() {
        if (body.scene == null) return;
        body.glyphScale = glyphWidth;
        glyphHeight = glyphWidth * body.font.glyphRatio;
        processText();
        allocateGlyphs();
        updateGlyphs();
    }

    function processText() numRequiredGlyphs = 0;

    function allocateGlyphs() {
        if (body.size < numRequiredGlyphs) body.size = numRequiredGlyphs * 2;
        for (ike in numRequiredGlyphs...body.size) body.getGlyphByID(ike).reset();
    }

    function updateGlyphs() {

    }
}
