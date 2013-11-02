package net.rezmason.scourge.textview;

import haxe.Utf8;

import net.rezmason.gl.utils.BufferUtil;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.Interaction;
import net.rezmason.scourge.textview.core.GlyphTexture;

using net.rezmason.scourge.textview.core.GlyphUtils;

class GlyphBody extends Body {

    inline static var CHAR:String = 'Ω';

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture, redrawHitAreas:Void->Void):Void {

        super(bufferUtil, glyphTexture, redrawHitAreas);

        growTo(1);

        var glyph:Glyph = glyphs[0];
        var charCode:Int = Utf8.charCodeAt(CHAR, 0);

        glyph.set_s(1);
        glyph.set_char(charCode, glyphTexture.font);
        glyph.set_paint(glyph.id | id << 16);
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {
        super.adjustLayout(stageWidth, stageHeight);
        setGlyphScale(0.8, 0.8 * glyphTexture.font.glyphRatio * stageWidth / stageHeight);

        transform.identity();
        transform.appendScale(1, -1, 1);
    }
}
