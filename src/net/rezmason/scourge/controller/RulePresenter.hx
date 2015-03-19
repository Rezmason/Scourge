package net.rezmason.scourge.controller;

import net.rezmason.scourge.textview.ColorPalette.*;
import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.praxis.PraxisTypes.AspectSet;
import net.rezmason.praxis.Reckoner;
import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.play.Game;
import net.rezmason.scourge.components.*;
import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.kawa.tween.easing.*;

using net.rezmason.scourge.textview.core.GlyphUtils;

class RulePresenter extends Reckoner {

    var ecce:Ecce = null;
    
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;

    @:final public function init(game:Game, ecce:Ecce) {
        primePointers(game.state, game.plan);
        this.ecce = ecce;
    }

    public function presentBoardChange(cause:String, index:Int, entity:Entity):Void {

        var view = entity.get(BoardNodeView);
        if (view == null || view.locus.value.isWall) return;

        var anim:GlyphAnimation = ecce.dispense([GlyphAnimation]).get(GlyphAnimation);
        anim.subject = entity;
        anim.duration = 1;
        anim.overlap = 0.5;
        anim.ease = Quad.easeInOut;
        anim.index = index;
        
        if (anim.topFrom == null) anim.topFrom = GlyphUtils.createGlyph();
        if (anim.topTo == null) anim.topTo = GlyphUtils.createGlyph();
        if (anim.bottomFrom == null) anim.bottomFrom = GlyphUtils.createGlyph();
        if (anim.bottomTo == null) anim.bottomTo = GlyphUtils.createGlyph();
        
        var nodeState = entity.get(BoardNodeState);
        populateGlyphs(anim.topFrom, anim.bottomFrom, nodeState.lastValues);
        populateGlyphs(anim.topTo,   anim.bottomTo,   nodeState.values);

        view.top.SET({char:97, r:anim.topTo.get_r(), g:anim.topTo.get_g(), b:anim.topTo.get_b()});
    }

    function populateGlyphs(topGlyph:Glyph, bottomGlyph:Glyph, values:AspectSet) {
        var occupier = values[occupier_];
        var isFilled = values[isFilled_] == TRUE;
        if (occupier != NULL) {
            var color = TEAM_COLORS[occupier];
            bottomGlyph.set_color(color * 0.4);
            topGlyph.set_color(isFilled ? color : BLACK);
        } else {
            bottomGlyph.set_color(BOARD_COLOR);
            topGlyph.set_color(isFilled ? WALL_COLOR : BLACK);
        }
    }
}
