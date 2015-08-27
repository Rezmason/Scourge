package net.rezmason.scourge.controller;

import net.rezmason.scourge.textview.ColorPalette.*;
import motion.easing.*;
import net.rezmason.scourge.Strings.*;
using net.rezmason.scourge.textview.core.GlyphUtils;

class EatRulePresenter extends RulePresenter {
    override function animateGlyphs() {
        var anim = createAnimation();
        var oldChar = anim.topFrom.get_char();
        populateGlyphs(anim.topFrom, anim.bottomFrom, spaceState.lastValues);
        anim.topFrom.set_char(oldChar);
        populateGlyphs(anim.topTo,   anim.bottomTo,   spaceState.values);
        anim.topTo.set_p(-0.03);
    }
}
