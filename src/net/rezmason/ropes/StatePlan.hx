package net.rezmason.ropes;

import net.rezmason.ropes.RopesTypes;

class StatePlan {

    public var stateAspectTemplate(default, null):AspectSet;
    public var playerAspectTemplate(default, null):AspectSet;
    public var nodeAspectTemplate(default, null):AspectSet;

    public var stateAspectLookup(default, null):AspectLookup;
    public var playerAspectLookup(default, null):AspectLookup;
    public var nodeAspectLookup(default, null):AspectLookup;

    public function new():Void {
        stateAspectTemplate = new AspectSet();
        playerAspectTemplate = new AspectSet();
        nodeAspectTemplate = new AspectSet();

        stateAspectLookup = new AspectLookup();
        playerAspectLookup = new AspectLookup();
        nodeAspectLookup = new AspectLookup();
    }

    public static inline function onState(plan:StatePlan, prop:AspectProperty):AspectPtr {
        return plan.stateAspectLookup[prop.id];
    }

    public static inline function onPlayer(plan:StatePlan, prop:AspectProperty):AspectPtr {
        return plan.playerAspectLookup[prop.id];
    }

    public static inline function onNode(plan:StatePlan, prop:AspectProperty):AspectPtr {
        return plan.nodeAspectLookup[prop.id];
    }

}
