package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class BodyAspect extends Aspect {
    public static var NODE_ID:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var HEAD:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var BODY_FIRST:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var BODY_NEXT:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var BODY_PREV:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};

    public static var TOTAL_AREA:AspectProperty = {id:Aspect.ids++, initialValue:0};

    public static var CAVITY_FIRST:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var CAVITY_NEXT:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var CAVITY_PREV:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
}
