package net.rezmason.praxis.state;

import haxe.ds.ArraySort;

import net.rezmason.grid.Cell;
import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.aspect.Aspect.*;
import net.rezmason.praxis.aspect.IdentityAspect;

using Lambda;
using net.rezmason.grid.GridUtils;
using net.rezmason.utils.Alphabetizer;
using net.rezmason.utils.MapUtils;
using net.rezmason.utils.pointers.Pointers;

class StatePlanner {
    public function new():Void {

    }

    public function planState(state:State, rules:Iterable<Rule>):StatePlan {
        if (rules == null) return null;

        var plan:StatePlan = new StatePlan();

        var globalRequirements:AspectRequirements = new AspectRequirements();
        var playerRequirements:AspectRequirements = new AspectRequirements();
        var cardRequirements:AspectRequirements = new AspectRequirements();
        var spaceRequirements:AspectRequirements = new AspectRequirements();

        for (rule in rules) {
            if (rule == null) continue;
            globalRequirements.absorb(rule.globalAspectRequirements);
            playerRequirements.absorb(rule.playerAspectRequirements);
            cardRequirements.absorb(rule.cardAspectRequirements);
            spaceRequirements.absorb(rule.spaceAspectRequirements);
            // trace(Type.getClassName(Type.getClass(rule)));
        }

        planAspects(globalRequirements, plan.globalAspectLookup, plan.globalAspectTemplate);
        planAspects(playerRequirements, plan.playerAspectLookup, plan.playerAspectTemplate);
        planAspects(cardRequirements, plan.cardAspectLookup, plan.cardAspectTemplate);
        planAspects(spaceRequirements, plan.spaceAspectLookup, plan.spaceAspectTemplate);

        return plan;
    }

    function planAspects(requirements:AspectRequirements, lookup:AspectLookup, template:AspectSet):Void {
        var source = new AspectSource();
        lookup[IdentityAspect.IDENTITY.id] = source.add(); // Index 0 is reserved for the aspects' ID
        for (id in requirements.keys().a2z()) {
            var prop:AspectProperty = requirements[id];
            var ptr:AspectPtr = source.add();
            lookup[prop.id] = ptr;
            template[ptr] = prop.initialValue;
        }
    }
}
