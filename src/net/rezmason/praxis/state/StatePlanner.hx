package net.rezmason.praxis.state;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.aspect.IdentityAspect;
import net.rezmason.praxis.rule.BaseRule;

using net.rezmason.utils.Alphabetizer;
using net.rezmason.utils.MapUtils;

class StatePlanner {
    public function new() {}

    public function planState(state:State, rules:Iterable<BaseRule<Dynamic>>):StatePlan {
        if (rules == null) return null;

        var plan = new StatePlan();

        var globalRequirements = new AspectRequirements();
        var playerRequirements = new AspectRequirements();
        var cardRequirements = new AspectRequirements();
        var spaceRequirements = new AspectRequirements();

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

    function planAspects<T>(requirements:AspectRequirements<T>, lookup:AspectLookup<T>, template:AspectPointable<T>) {
        var source = new AspectSource();
        lookup[IdentityAspect.IDENTITY.id] = source.add(); // Index 0 is reserved for the aspects' ID
        for (id in requirements.keys().a2z()) {
            var prop = requirements[id];
            var ptr = source.add();
            lookup[prop.id] = ptr;
            template[ptr] = prop.initialValue;
        }
    }
}
