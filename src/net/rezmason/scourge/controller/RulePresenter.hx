package net.rezmason.scourge.controller;

import net.kawa.tween.easing.*;
import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.praxis.PraxisTypes.AspectSet;
import net.rezmason.praxis.Reckoner;
import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.play.Game;
import net.rezmason.scourge.Strings.*;
import net.rezmason.scourge.components.*;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.textview.ColorPalette.*;
import net.rezmason.scourge.textview.core.Glyph;

using net.rezmason.scourge.textview.core.GlyphUtils;

class RulePresenter extends Reckoner {

    var ecce:Ecce = null;
    
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.HEAD) var head_;

    @:final public function init(game:Game, ecce:Ecce) {
        primePointers(game.state, game.plan);
        this.ecce = ecce;
    }

    public function presentBoardChange(cause:String, index:Null<Int>, entity:Entity):Void {

        var view = entity.get(BoardNodeView);
        if (view == null || view.locus.value.isWall) return;
        var nodeState = entity.get(BoardNodeState);
        if (index != null) {
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

            anim.topFrom.copyFrom(view.top);
            anim.topTo.copyFrom(view.top);
            anim.bottomFrom.copyFrom(view.bottom);
            anim.bottomTo.copyFrom(view.bottom);
            
            populateGlyphs(anim.topFrom, anim.bottomFrom, nodeState.lastValues);
            populateGlyphs(anim.topTo,   anim.bottomTo,   nodeState.values);
        } else {
            populateGlyphs(view.top,     view.bottom,     nodeState.values);
        }
    }

    function populateGlyphs(topGlyph:Glyph, bottomGlyph:Glyph, values:AspectSet) {
        var occupier = values[occupier_];
        var isFilled = values[isFilled_] == TRUE;
        
        if (occupier != NULL) {
            var color = TEAM_COLORS[occupier];
            bottomGlyph.set_color(color * 0.4);
            topGlyph.set_color(isFilled ? color : BLACK);
            if (isFilled) {
                var code = (getPlayer(occupier)[head_] == getID(values)) ? HEAD_CODE : BODY_CODE;
                bottomGlyph.set_char(code);
                topGlyph.set_char(code);
            } else {
                bottomGlyph.set_char(CAVITY_CODE);
                topGlyph.set_char(-1);
            }
        } else {
            bottomGlyph.set_color(BOARD_COLOR);
            topGlyph.set_color(isFilled ? WALL_COLOR : BLACK);
        }
    }
}
