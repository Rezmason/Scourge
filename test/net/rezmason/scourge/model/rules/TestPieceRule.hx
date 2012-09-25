package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.PieceAspect;

using net.rezmason.utils.Pointers;

typedef TestPieceConfig = {
    var pieceID:Int;
    var reflection:Int;
    var rotation:Int;
}

class TestPieceRule extends Rule {

    @state(PieceAspect.PIECE_ID) var pieceID_:AspectPtr;
    @state(PieceAspect.PIECE_REFLECTION) var pieceReflection_:AspectPtr;
    @state(PieceAspect.PIECE_ROTATION) var pieceRotation_:AspectPtr;

    private var cfg:TestPieceConfig;

    public function new(cfg:TestPieceConfig):Void {
        super();
        this.cfg = cfg;
    }

    override public function init(state:State, plan:StatePlan):Void {
        super.init(state, plan);
        state.aspects.mod(pieceID_, cfg.pieceID);
        state.aspects.mod(pieceReflection_, cfg.reflection);
        state.aspects.mod(pieceRotation_, cfg.rotation);
    }
}
