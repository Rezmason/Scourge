package net.rezmason.scourge.controller;

import net.rezmason.scourge.ScourgeColorPalette.*;
import motion.easing.*;
import net.rezmason.scourge.ScourgeStrings.*;
using net.rezmason.hypertype.core.GlyphUtils;

class EatRulePresenter extends RulePresenter {
    override function animateGlyphs() {
        var anim = createAnimation();
        var oldChar = anim.topFrom.get_char();
        populateGlyphs(anim.topFrom, anim.bottomFrom, spaceState.lastValues, spaceState.petriData);
        anim.topFrom.set_char(oldChar);
        populateGlyphs(anim.topTo,   anim.bottomTo,   spaceState.values, spaceState.petriData);
        anim.topTo.set_char(oldChar);
        anim.topTo.set_p(-0.05);
    }
}
