package net.rezmason.scourge.controller;

import net.rezmason.scourge.textview.ColorPalette.*;
import net.kawa.tween.easing.*;
import net.rezmason.scourge.Strings.*;
using net.rezmason.scourge.textview.core.GlyphUtils;

class EatCellsRulePresenter extends RulePresenter {
    override function animateGlyphs():Bool {
        var anim = createAnimation();
        var oldChar = anim.topFrom.get_char();
        populateGlyphs(anim.topFrom, anim.bottomFrom, nodeState.lastValues);
        anim.topFrom.set_char(oldChar);
        populateGlyphs(anim.topTo,   anim.bottomTo,   nodeState.values);
        anim.topTo.set_p(-0.03);
        return true;
    }
}
