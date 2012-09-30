package net.rezmason.scourge.model.aspects;

import net.rezmason.scourge.model.ModelTypes;

class PieceAspect extends Aspect {
    public static var PIECES_PICKED:AspectProperty = {id:Aspect.ids++, initialValue:0};
    public static var PIECE_FIRST:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var PIECE_NEXT:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var PIECE_PREV:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var PIECE_HAT_FIRST:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var PIECE_HAT_PLAYER:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var PIECE_HAT_NEXT:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var PIECE_HAT_PREV:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};

    public static var PIECE_ID:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var PIECE_TABLE_ID:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
    public static var PIECE_REFLECTION:AspectProperty = {id:Aspect.ids++, initialValue:0};
    public static var PIECE_ROTATION:AspectProperty = {id:Aspect.ids++, initialValue:0};
    public static var PIECE_OPTION_ID:AspectProperty = {id:Aspect.ids++, initialValue:Aspect.NULL};
}
