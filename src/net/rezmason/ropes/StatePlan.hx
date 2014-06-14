package net.rezmason.ropes;

import net.rezmason.ropes.RopesTypes;

class StatePlan {

    public var globalAspectTemplate(default, null):AspectSet;
    public var playerAspectTemplate(default, null):AspectSet;
    public var nodeAspectTemplate(default, null):AspectSet;

    public var globalAspectLookup(default, null):AspectLookup;
    public var playerAspectLookup(default, null):AspectLookup;
    public var nodeAspectLookup(default, null):AspectLookup;

    public function new():Void {
        globalAspectTemplate = new AspectSet();
        playerAspectTemplate = new AspectSet();
        nodeAspectTemplate = new AspectSet();

        globalAspectLookup = new AspectLookup();
        playerAspectLookup = new AspectLookup();
        nodeAspectLookup = new AspectLookup();
    }

    public static inline function onState(plan:StatePlan, prop:AspectProperty):AspectPtr {
        return plan.globalAspectLookup[prop.id];
    }

    public static inline function onPlayer(plan:StatePlan, prop:AspectProperty):AspectPtr {
        return plan.playerAspectLookup[prop.id];
    }

    public static inline function onNode(plan:StatePlan, prop:AspectProperty):AspectPtr {
        return plan.nodeAspectLookup[prop.id];
    }

}
