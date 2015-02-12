package net.rezmason.ropes.state;

import haxe.ds.ArraySort;

import net.rezmason.ropes.grid.GridLocus;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.aspect.Aspect.*;

using Lambda;
using net.rezmason.ropes.grid.GridUtils;
using net.rezmason.utils.Alphabetizer;
using net.rezmason.utils.MapUtils;
using net.rezmason.utils.Pointers;

class StatePlanner {
    public function new():Void {

    }

    public function planState(state:State, rules:Iterable<Rule>):StatePlan {
        if (rules == null) return null;

        var plan:StatePlan = new StatePlan();

        var globalRequirements:AspectRequirements = new AspectRequirements();
        var playerRequirements:AspectRequirements = new AspectRequirements();
        var nodeRequirements:AspectRequirements = new AspectRequirements();

        for (rule in rules) {
            if (rule == null) continue;
            globalRequirements.absorb(rule.globalAspectRequirements);
            playerRequirements.absorb(rule.playerAspectRequirements);
            nodeRequirements.absorb(rule.nodeAspectRequirements);
            // trace(Type.getClassName(Type.getClass(rule)));
        }

        planAspects(globalRequirements, plan.globalAspectLookup, plan.globalAspectTemplate, state.key);
        planAspects(playerRequirements, plan.playerAspectLookup, plan.playerAspectTemplate, state.key);
        planAspects(nodeRequirements, plan.nodeAspectLookup, plan.nodeAspectTemplate, state.key);

        return plan;
    }

    function planAspects(requirements:AspectRequirements, lookup:AspectLookup, template:AspectSet, key:PtrKey):Void {
        var itr:Int = 1; // Index 0 is reserved for the aspects' ID
        for (id in requirements.keys().a2z()) {
            var prop:AspectProperty = requirements[id];
            var ptr:AspectPtr = template.ptr(itr, key);
            lookup[prop.id] = ptr;
            template[ptr] = prop.initialValue;
            itr++;
        }
    }
}
