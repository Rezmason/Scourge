package net.rezmason.ropes;

import net.rezmason.ropes.GridNode;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.Aspect;

using Lambda;
using net.rezmason.ropes.GridUtils;
using net.rezmason.utils.ArrayUtils;
using net.rezmason.utils.Pointers;

class StatePlanner {
    public function new():Void {

    }

    public function planState(state:State, rules:Array<Rule>):StatePlan {
        if (rules == null) return null;

        var plan:StatePlan = new StatePlan();

        for (ike in 0...rules.length) if (rules.indexOf(rules[ike]) != ike) rules[ike] = null;
        rules = rules.copy();
        while (rules.remove(null)) {}

        var stateRequirements:AspectRequirements = new AspectRequirements();
        var playerRequirements:AspectRequirements = new AspectRequirements();
        var nodeRequirements:AspectRequirements = new AspectRequirements();

        for (rule in rules) {
            stateRequirements.absorb(rule.stateAspectRequirements);
            playerRequirements.absorb(rule.playerAspectRequirements);
            nodeRequirements.absorb(rule.nodeAspectRequirements);
        }

        planAspects(stateRequirements, plan.stateAspectLookup, plan.stateAspectTemplate);
        planAspects(playerRequirements, plan.playerAspectLookup, plan.playerAspectTemplate);
        planAspects(nodeRequirements, plan.nodeAspectLookup, plan.nodeAspectTemplate);

        return plan;
    }

    inline function planAspects(requirements:AspectRequirements, lookup:AspectLookup, template:AspectSet):Void {
        for (ike in 0...requirements.length) {
            var prop:AspectProperty = requirements[ike];
            lookup[prop.id] = ike.intToPointer();
            template[ike] = prop.initialValue;
        }
    }
}
