package net.rezmason.scourge.controller;

import net.rezmason.ecce.Ecce;
import net.rezmason.ecce.Entity;
import net.rezmason.ecce.Query;
import net.rezmason.ropes.Aspect.*;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.Reckoner;
import net.rezmason.scourge.controller.PlayerSystem;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.aspects.*;
import net.rezmason.scourge.components.*;
import net.rezmason.utils.Pointers;

class Presenter extends Reckoner {

    var ecce:Ecce = null;
    
    // @node(FreshnessAspect.FRESHNESS) var freshness_;
    // @global(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    public function new(ecce:Ecce) {
        super();
        this.ecce = ecce;
        
    }

}
