package net.rezmason.scourge.model.rules;

//import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.aspects.PieceAspect;

using net.rezmason.utils.Pointers;

typedef TestPieceConfig = {
    var pieceTableID:Int;
    var reflection:Int;
    var rotation:Int;
}

class TestPieceRule extends RopesRule<TestPieceConfig> {

    @global(PieceAspect.PIECE_TABLE_ID) var pieceTableID_:AspectPtr;
    @global(PieceAspect.PIECE_REFLECTION) var pieceReflection_:AspectPtr;
    @global(PieceAspect.PIECE_ROTATION) var pieceRotation_:AspectPtr;

    override public function _prime():Void {
        state.global[pieceTableID_] = params.pieceTableID;
        state.global[pieceReflection_] = params.reflection;
        state.global[pieceRotation_] = params.rotation;
    }
}
