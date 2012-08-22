package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class TestAspect extends Aspect {
    public static var VALUE:AspectProperty = {id:Aspect.ids++, initialValue:1};
}
