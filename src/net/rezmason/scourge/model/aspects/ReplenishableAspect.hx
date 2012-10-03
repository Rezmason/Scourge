package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class ReplenishableAspect extends Aspect {
    public static var STATE_REP_FIRST:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var PLAYER_REP_FIRST:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var NODE_REP_FIRST:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};

    public static var REP_NEXT:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var REP_PREV:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var REP_ID:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};

    public static var REP_PROP_LOOKUP:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var REP_STEP:AspectProperty = {id:Aspect.ids++, initialValue:0};
}
