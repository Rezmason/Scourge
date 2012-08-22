package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class PlyAspect extends Aspect {
    public static var CURRENT_PLAYER:AspectProperty = {id:Aspect.ids++, initialValue:0};
}
