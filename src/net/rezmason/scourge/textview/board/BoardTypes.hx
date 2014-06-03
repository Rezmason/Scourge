package net.rezmason.scourge.textview.board;

import net.rezmason.scourge.textview.board.BoardEffects;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.utils.display.FlatFont;

typedef NodeTween = {
    var from:NodeProps;
    var to:NodeProps;
    var view:NodeView;
    var start:Float;
    var end:Float;
    var duration:Float;
    var effect:BoardEffect;
}

typedef NodeProps = {
    var topSize:Float;
    var topChar:Int;
    var topColor:Color;
    var bottomSize:Float;
    var bottomChar:Int;
    var bottomColor:Color;
    var topFont:FlatFont;
    var bottomFont:FlatFont;
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
