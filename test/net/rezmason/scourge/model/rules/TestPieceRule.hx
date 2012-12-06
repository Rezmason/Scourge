package net.rezmason.scourge.model.rules;

//import net.rezmason.ropes.Types;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.PieceAspect;

using net.rezmason.utils.Pointers;

typedef TestPieceConfig = {
    var pieceTableID:Int;
    var reflection:Int;
    var rotation:Int;
}

class TestPieceRule extends Rule {

    @state(PieceAspect.PIECE_TABLE_ID) var pieceTableID_:AspectPtr;
    @state(PieceAspect.PIECE_REFLECTION) var pieceReflection_:AspectPtr;
    @state(PieceAspect.PIECE_ROTATION) var pieceRotation_:AspectPtr;

    private var cfg:TestPieceConfig;

    public function new(cfg:TestPieceConfig):Void {
        super();
        this.cfg = cfg;
    }

    override public function init():Void {
        state.aspects.mod(pieceTableID_, cfg.pieceTableID);
        state.aspects.mod(pieceReflection_, cfg.reflection);
        state.aspects.mod(pieceRotation_, cfg.rotation);
    }
}
