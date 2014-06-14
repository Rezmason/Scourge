package net.rezmason.scourge.model.rules;

//import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.PieceAspect;

using net.rezmason.utils.Pointers;

typedef TestPieceConfig = {
    var pieceTableID:Int;
    var reflection:Int;
    var rotation:Int;
}

class TestPieceRule extends Rule {

    @global(PieceAspect.PIECE_TABLE_ID) var pieceTableID_:AspectPtr;
    @global(PieceAspect.PIECE_REFLECTION) var pieceReflection_:AspectPtr;
    @global(PieceAspect.PIECE_ROTATION) var pieceRotation_:AspectPtr;

    private var cfg:TestPieceConfig;

    override public function _init(cfg:TestPieceConfig):Void { this.cfg = cfg; }

    override public function _prime():Void {
        state.globals[pieceTableID_] = cfg.pieceTableID;
        state.globals[pieceReflection_] = cfg.reflection;
        state.globals[pieceRotation_] = cfg.rotation;
    }
}
