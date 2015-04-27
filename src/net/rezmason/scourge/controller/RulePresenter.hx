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
    
    var subject:Entity;
    var nodeView:BoardNodeView;
    var nodeState:BoardNodeState;
    var animationEntities:Array<Entity>;
    var effectOverlap(default, null):Float;
    
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.HEAD) var head_;

    public function new(game:Game, ecce:Ecce) {
        super();
        primePointers(game.state, game.plan);
        this.ecce = ecce;
        effectOverlap = 0;
    }

    @:final public function presentBoardEffect(subject:Entity):Array<Entity> {
        nodeState = subject.get(BoardNodeState);
        if (nodeState == null || nodeState.petriData.isWall) return null;
        this.subject = subject;
        nodeView = subject.get(BoardNodeView);
        animateGlyphs();
        var entities = animationEntities;
        animationEntities = null;
        if (entities != null) nodeView.changed = true;
        return entities;
    }

    @:final function createAnimation() {
        var animEntity = ecce.dispense([GlyphAnimation]);
        if (animationEntities == null) animationEntities = [];
        animationEntities.push(animEntity);

        var anim = animEntity.get(GlyphAnimation);
        anim.subject = subject;
        
        if (anim.topFrom == null) anim.topFrom = GlyphUtils.createGlyph();
        if (anim.topTo == null) anim.topTo = GlyphUtils.createGlyph();
        if (anim.bottomFrom == null) anim.bottomFrom = GlyphUtils.createGlyph();
        if (anim.bottomTo == null) anim.bottomTo = GlyphUtils.createGlyph();

        anim.startTime = 0;
        anim.duration = 0.125;
        anim.ease = Quad.easeInOut;

        anim.topFrom.copyFrom(nodeView.top);
        anim.topTo.copyFrom(nodeView.top);
        anim.bottomFrom.copyFrom(nodeView.bottom);
        anim.bottomTo.copyFrom(nodeView.bottom);

        return anim;
    }

    @:final function populateGlyphs(topGlyph:Glyph, bottomGlyph:Glyph, values:AspectSet) {
        var occupier = values[occupier_];
        var isFilled = values[isFilled_] == TRUE;
        
        if (occupier != NULL) {
            var color = TEAM_COLORS[occupier];
            if (isFilled) {
                var code = (getPlayer(occupier)[head_] == getID(values)) ? HEAD_CODE : BODY_CODE;
                bottomGlyph.SET({char:code, color:color * 0.3, s:1.8});
                topGlyph.SET({char:code, color:color, f:0.6});
            } else {
                bottomGlyph.SET({char:BOARD_CODE, color:color * 0.3, s:1});
                topGlyph.SET({char:BODY_CODE, color:BLACK});
            }
        } else {
            bottomGlyph.set_color(BOARD_COLOR);
            bottomGlyph.set_s(1);
            if (!isFilled) {
                bottomGlyph.set_char(BOARD_CODE);
                topGlyph.set_color(BLACK);
            }
        }
    }

    function animateGlyphs() {
        var anim = createAnimation();
        populateGlyphs(anim.topFrom, anim.bottomFrom, nodeState.lastValues);
        populateGlyphs(anim.topTo,   anim.bottomTo,   nodeState.values);

        anim.bottomTo.set_pos(nodeState.petriData.pos);
        anim.topTo.set_pos(nodeState.petriData.pos);
        anim.topTo.set_p(-0.05);
    }
}
