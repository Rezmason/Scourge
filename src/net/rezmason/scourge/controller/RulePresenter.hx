package net.rezmason.scourge.controller;

import motion.easing.*;
import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.Reckoner;
import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.play.Game;
import net.rezmason.scourge.ScourgeStrings.*;
import net.rezmason.scourge.components.*;
import net.rezmason.scourge.game.body.BodyAspect;
import net.rezmason.scourge.game.body.OwnershipAspect;
import net.rezmason.scourge.game.build.PetriTypes;
import net.rezmason.scourge.ScourgeColorPalette.*;
import net.rezmason.hypertype.core.Glyph;

using net.rezmason.hypertype.core.GlyphUtils;

class RulePresenter extends Reckoner {

    var ecce:Ecce = null;
    
    var subject:Entity;
    var spaceView:BoardSpaceView;
    var spaceState:BoardSpaceState;
    var animationEntities:Array<Entity>;
    var effectOverlap(default, null):Float;
    
    @space(OwnershipAspect.IS_FILLED) var isFilled_;
    @space(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.HEAD) var head_;

    public function init(game:Game, ecce:Ecce) {
        primePointers(game.state, game.plan);
        this.ecce = ecce;
        effectOverlap = 0;
    }

    @:final public function presentBoardEffect(subject:Entity):Array<Entity> {
        spaceState = subject.get(BoardSpaceState);
        if (spaceState == null || spaceState.petriData.isWall) return null;
        this.subject = subject;
        spaceView = subject.get(BoardSpaceView);
        animateGlyphs();
        var entities = animationEntities;
        animationEntities = null;
        if (entities != null) {
            var lastAnim = entities[entities.length - 1].get(GlyphAnimation);
            spaceView.changed = true;
            spaceView.lastTopTo.copyFrom(lastAnim.topTo);
            spaceView.lastBottomTo.copyFrom(lastAnim.bottomTo);
        }
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
        anim.ease = Quad.easeInOut.calculate;

        anim.topFrom.copyFrom(spaceView.lastTopTo);
        anim.topTo.copyFrom(spaceView.lastTopTo);
        anim.bottomFrom.copyFrom(spaceView.lastBottomTo);
        anim.bottomTo.copyFrom(spaceView.lastBottomTo);

        return anim;
    }

    @:final function populateGlyphs(topGlyph:Glyph, bottomGlyph:Glyph, values:Space, petriData:PetriData) {
        var occupier = values[occupier_];
        var isFilled = values[isFilled_] == TRUE;
        
        if (occupier != NULL) {
            var color = TEAM_COLORS[occupier];
            if (isFilled) {
                var code = BODY_CODE;
                if (getPlayer(occupier)[head_] == getID(values)) code = HEAD_CODE;
                bottomGlyph.SET({char:code, color:color * 0.3, s:2.5});
                topGlyph.SET({char:code, color:color, f:0.1, s:1.5});
            } else {
                bottomGlyph.SET({char:BOARD_CODE, color:color * 0.3, s:1.5});
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
        populateGlyphs(anim.topFrom, anim.bottomFrom, spaceState.lastValues, spaceState.petriData);
        populateGlyphs(anim.topTo,   anim.bottomTo,   spaceState.values, spaceState.petriData);

        anim.bottomTo.set_pos(spaceState.petriData.pos);
        anim.topTo.set_pos(spaceState.petriData.pos);
        anim.topTo.set_p(-0.05);
    }
}
