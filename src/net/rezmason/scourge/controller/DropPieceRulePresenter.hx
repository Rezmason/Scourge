package net.rezmason.scourge.controller;

import net.rezmason.scourge.ScourgeColorPalette.*;
import motion.easing.*;
import net.rezmason.scourge.ScourgeStrings.*;
using net.rezmason.hypertype.core.GlyphUtils;

class DropPieceRulePresenter extends RulePresenter {
    override function animateGlyphs() {
        var slam = createAnimation();
        populateGlyphs(slam.topFrom, slam.bottomFrom, spaceState.lastValues, spaceState.petriData);
        slam.topFrom.SET({color:BLACK, s:1.2, f:0.2, char:BODY_CODE, p:-0.5});
        populateGlyphs(slam.topTo, slam.bottomTo, spaceState.values, spaceState.petriData);
        slam.bottomTo.SET({r:slam.topTo.get_r(), g:slam.topTo.get_g(), b:slam.topTo.get_b()});
        slam.topTo.SET({color:WHITE, char:slam.topFrom.get_char(), s:1.2, f:0.2, p:-0.05});
        
        slam.duration = 0.125;
        slam.ease = Linear.easeNone.calculate;

        var cool = createAnimation();
        cool.topFrom.copyFrom(slam.topTo);
        cool.bottomFrom.copyFrom(slam.bottomTo);
        populateGlyphs(cool.topTo, cool.bottomTo, spaceState.values, spaceState.petriData);
        cool.bottomTo.set_pos(spaceState.petriData.pos);
        cool.topTo.set_pos(spaceState.petriData.pos);
        cool.topTo.set_p(-0.03);

        cool.ease = Quad.easeIn.calculate;
        cool.startTime = slam.duration;
        cool.duration = 0.5;
    }
}
