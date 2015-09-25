package net.rezmason.scourge.game.meta;

import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.Builder;

using net.rezmason.utils.Alphabetizer;
using net.rezmason.praxis.aspect.AspectUtils;

class ReplenishBuilder extends Builder<ReplenishParams> {

    @extra(ReplenishableAspect.REP_STEP) var repStep_;

    override public function init():Void {
        for (key in params.globalProperties.keys().a2z() ) addGlobalAspectRequirement(params.globalProperties[key].prop);
        for (key in params.playerProperties.keys().a2z() ) addPlayerAspectRequirement(params.playerProperties[key].prop);
        for (key in params.cardProperties  .keys().a2z() ) addCardAspectRequirement  (params.cardProperties  [key].prop);
        for (key in params.spaceProperties .keys().a2z() ) addSpaceAspectRequirement (params.spaceProperties [key].prop);
    }

    override public function prime():Void {

        // As a meta-rule, ReplenishRule has a relatively complex init function.

        // Create the replenishables
        for (repProp in params.globalProperties) {
            var replenishable = addExtra();
            repProp.replenishableID = getID(replenishable);
            repProp.replenishablePtr = plan.onGlobal(repProp.prop);
        }

        for (repProp in params.playerProperties) {
            var replenishable = addExtra();
            repProp.replenishableID = getID(replenishable);
            repProp.replenishablePtr = plan.onPlayer(repProp.prop);
        }

        for (repProp in params.cardProperties) {
            var replenishable = addExtra();
            repProp.replenishableID = getID(replenishable);
            repProp.replenishablePtr = plan.onCard(repProp.prop);
        }

        for (repProp in params.spaceProperties) {
            var replenishable = addExtra();
            repProp.replenishableID = getID(replenishable);
            repProp.replenishablePtr = plan.onSpace(repProp.prop);
        }
    }
}

