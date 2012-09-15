package net.rezmason.scourge.model;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.Aspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;
using Std;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.ArrayUtils;
using net.rezmason.utils.Pointers;

class StatePlanner {
    public function new():Void {

    }

    public function planState(state:State, rules:Array<Rule>):StatePlan {
        if (rules == null) return null;

        var plan:StatePlan = new StatePlan();

        while (rules.has(null)) rules.remove(null);

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

        for (rule in rules) rule.init(state, plan);

        return plan;
    }

    inline function planAspects(requirements:AspectRequirements, lookup:AspectLookup, template:AspectSet):Void {
        for (ike in 0...requirements.length) {
            var prop:AspectProperty = requirements[ike];
            lookup[prop.id] = ike.pointerArithmetic();
            template[ike] = prop.initialValue;
        }
    }
}
