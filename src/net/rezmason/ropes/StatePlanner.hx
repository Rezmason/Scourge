package net.rezmason.ropes;

import haxe.ds.ArraySort;
import net.rezmason.ropes.GridNode;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.Aspect;
import net.rezmason.utils.StringSort;

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

        planAspects(stateRequirements, plan.stateAspectLookup, plan.stateAspectTemplate, state.key);
        planAspects(playerRequirements, plan.playerAspectLookup, plan.playerAspectTemplate, state.key);
        planAspects(nodeRequirements, plan.nodeAspectLookup, plan.nodeAspectTemplate, state.key);

        return plan;
    }

    function planAspects(requirements:AspectRequirements, lookup:AspectLookup, template:AspectSet, key:PtrSet):Void {
        ArraySort.sort(requirements, propSort);
        for (ike in 0...requirements.length) {
            var prop:AspectProperty = requirements[ike];
            lookup.set(prop.id, ike.intToPointer(key));
            template[ike] = prop.initialValue;
        }
    }

    inline static function propSort(a:AspectProperty, b:AspectProperty):Int { return StringSort.sort(a.id, b.id); }
}
