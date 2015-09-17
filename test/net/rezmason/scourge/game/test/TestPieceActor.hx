package net.rezmason.scourge.game.test;

import net.rezmason.praxis.rule.Actor;
import net.rezmason.scourge.game.piece.PieceAspect;

typedef TestPieceParams = {
    var pieceTableID:Int;
    var reflection:Int;
    var rotation:Int;
}

class TestPieceActor extends Actor<TestPieceParams> {

    @global(PieceAspect.PIECE_TABLE_ID, true) var pieceTableID_:AspectPointer;
    @global(PieceAspect.PIECE_REFLECTION, true) var pieceReflection_:AspectPointer;
    @global(PieceAspect.PIECE_ROTATION, true) var pieceRotation_:AspectPointer;

    override public function prime():Void {
        state.global[pieceTableID_] = params.pieceTableID;
        state.global[pieceReflection_] = params.reflection;
        state.global[pieceRotation_] = params.rotation;
    }
}
