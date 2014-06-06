package net.rezmason.scourge.textview.board;

import net.rezmason.scourge.textview.board.BoardEffects;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.utils.display.FlatFont;

typedef NodeTween = {
    var from:NodeProps;
    var to:NodeProps;
    var view:NodeView;
    var start:Float;
    var duration:Float;
    var ease:Float->Float;
    var cause:String;
}

typedef NodeGlyphProps = {
    var size:Float;
    var char:Int;
    var color:Color;
    var pop:Float;
    var thickness:Float;
}

typedef NodeProps = {
    var top:NodeGlyphProps;
    var bottom:NodeGlyphProps;
}

typedef NodeView = {
    var bottomGlyph:Glyph;
    var topGlyph:Glyph;
    var uiGlyph:Glyph;
    var x:Float;
    var y:Float;
    var z:Float;
    var props:NodeProps;
}
