package net.rezmason.scourge.game.test;

//import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.scourge.game.piece.PieceAspect;

using net.rezmason.utils.pointers.Pointers;

typedef TestPieceParams = {
    var pieceTableID:Int;
    var reflection:Int;
    var rotation:Int;
}

class TestPieceRule extends BaseRule<TestPieceParams> {

    @global(PieceAspect.PIECE_TABLE_ID, true) var pieceTableID_:AspectPtr;
    @global(PieceAspect.PIECE_REFLECTION, true) var pieceReflection_:AspectPtr;
    @global(PieceAspect.PIECE_ROTATION, true) var pieceRotation_:AspectPtr;

    override public function _prime():Void {
        state.global[pieceTableID_] = params.pieceTableID;
        state.global[pieceReflection_] = params.reflection;
        state.global[pieceRotation_] = params.rotation;
    }
}
