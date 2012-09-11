package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class BodyAspect extends Aspect {
    public static var HEAD:AspectProperty = {id:Aspect.ids++, initialValue:-1};
    public static var BODY_FIRST:AspectProperty = {id:Aspect.ids++, initialValue:-1};
    public static var BODY_NEXT:AspectProperty = {id:Aspect.ids++, initialValue:-1};
}
