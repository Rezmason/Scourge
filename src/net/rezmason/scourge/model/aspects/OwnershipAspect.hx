package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class OwnershipAspect extends Aspect {
    public static var IS_FILLED:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.FALSE};
    public static var OCCUPIER:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
}
