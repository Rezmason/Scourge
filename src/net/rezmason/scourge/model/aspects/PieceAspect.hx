package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class PieceAspect extends Aspect {
    public static var PIECE_ID:AspectProperty = {id:Aspect.ids++, initialValue:-1};
    public static var PIECE_REFLECTION:AspectProperty = {id:Aspect.ids++, initialValue:0};
    public static var PIECE_ROTATION:AspectProperty = {id:Aspect.ids++, initialValue:0};
}
