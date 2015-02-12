package net.rezmason.scourge.controller;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.ecce.Query;
import net.rezmason.ropes.aspect.Aspect.*;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.Reckoner;
import net.rezmason.scourge.controller.PlayerSystem;
import net.rezmason.ropes.Game;
import net.rezmason.scourge.model.aspects.*;
import net.rezmason.scourge.components.*;
import net.rezmason.utils.Pointers;

class Presenter extends Reckoner {

    var ecce:Ecce = null;
    
    // @node(FreshnessAspect.FRESHNESS) var freshness_;
    // @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    @:final public function init(game:Game, ecce:Ecce) {
        primePointers(game.state, game.plan);
        this.ecce = ecce;
    }

    public function presentBoardChange(cause:String, index:Int, entity:Entity):Void {
        var anim:GlyphAnimation = ecce.dispense([GlyphAnimation]).get(GlyphAnimation);
        anim.subject = entity;

        anim.duration = 1;
        anim.overlap = 0.5;
        anim.index = index;
    }
}
