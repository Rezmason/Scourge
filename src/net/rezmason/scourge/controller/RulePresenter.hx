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
        
        var space = entity.get(BoardSpace);
        populateGlyphs(anim.topFrom, anim.bottomFrom, space.lastValues);
        populateGlyphs(anim.topTo,   anim.bottomTo,   space.values);
    }

    function populateGlyphs(topGlyph:Glyph, bottomGlyph:Glyph, values:AspectSet) {
        var occupier = values[occupier_];
        var isFilled = values[isFilled_] == TRUE;
        if (occupier != NULL) {
            var color = TEAM_COLORS[occupier];
            bottomGlyph.set_color(color * 0.4);
            if (isFilled) topGlyph.set_color(color);
        } else {
            bottomGlyph.set_color(BOARD_COLOR);
            if (isFilled) topGlyph.set_color(WALL_COLOR);
        }
    }
}
