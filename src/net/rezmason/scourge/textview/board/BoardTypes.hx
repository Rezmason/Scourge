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
    var pos:XYZ;
    var thickness:Float;
}

typedef NodeProps = {
    var top:NodeGlyphProps;
    var bottom:NodeGlyphProps;
    var waveMult:Float;
}

typedef NodeView = {
    var bottomGlyph:Glyph;
    var topGlyph:Glyph;
    var uiGlyph:Glyph;
    var pos:XYZ;
    var props:NodeProps;
    var waveMult:Float;
    var waveHeight:Float;
    var distance:Int;
    var occupier:Int;
    var topSize:Float;
    var topZ:Float;
}

typedef CauseTime = {
    var cause:String;
    var time:Float;
};
