package net.rezmason.scourge.controller;

import net.rezmason.scourge.textview.ColorPalette.*;
import net.kawa.tween.easing.*;
import net.rezmason.scourge.Strings.*;
using net.rezmason.scourge.textview.core.GlyphUtils;

class DropPieceRulePresenter extends RulePresenter {
    override function animateGlyphs() {
        var slam = createAnimation();
        populateGlyphs(slam.topFrom, slam.bottomFrom, spaceState.lastValues);
        slam.topFrom.SET({color:BLACK, s:1.2, f:0.7, char:BODY_CODE, p:-0.5});
        populateGlyphs(slam.topTo, slam.bottomTo, spaceState.values);
        slam.topTo.SET({color:WHITE, char:slam.topFrom.get_char(), s:1.2, f:0.7, p:-0.05});
        
        slam.duration = 0.125;
        slam.ease = Linear.easeIn;

        var cool = createAnimation();
        cool.topFrom.copyFrom(slam.topTo);
        cool.bottomFrom.copyFrom(slam.bottomTo);
        populateGlyphs(cool.topTo, cool.bottomTo, spaceState.values);
        cool.bottomTo.set_pos(spaceState.petriData.pos);
        cool.topTo.set_pos(spaceState.petriData.pos);
        cool.topTo.set_p(-0.03);

        cool.startTime = slam.duration;
        cool.duration = 0.25;
    }
}
