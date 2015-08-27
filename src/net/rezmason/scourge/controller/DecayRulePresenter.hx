package net.rezmason.scourge.controller;

import net.rezmason.scourge.textview.ColorPalette.*;
import motion.easing.*;
using net.rezmason.scourge.textview.core.GlyphUtils;

class DecayRulePresenter extends RulePresenter {

    override function animateGlyphs() {
        var wither = createAnimation();
        wither.topTo.SET({color:WHITE * 0.5 + wither.topTo.get_color() * 0.5, f:0.4});
        wither.bottomTo.set_color(BLACK);
        
        wither.duration = 0.5;
        wither.ease = Linear.easeNone.calculate;

        var fade = createAnimation();
        fade.topFrom.copyFrom(wither.topTo);
        fade.bottomFrom.copyFrom(wither.bottomTo);
        populateGlyphs(fade.topTo, fade.bottomTo, spaceState.values);
        fade.topTo.set_p(0.02);
        fade.startTime = wither.duration + Math.random() * 0.5;
        fade.duration = 0.5;
    }
}
