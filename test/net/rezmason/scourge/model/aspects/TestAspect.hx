package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class TestAspect extends Aspect {
    public static var VALUE_1:AspectProperty = {id:Aspect.ids++, initialValue:0};
    public static var VALUE_2:AspectProperty = {id:Aspect.ids++, initialValue:0};
    public static var VALUE_3:AspectProperty = {id:Aspect.ids++, initialValue:0};
}
