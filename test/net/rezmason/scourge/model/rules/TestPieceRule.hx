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

    static var stateReqs:AspectRequirements;

    private var cfg:TestPieceConfig;

    public function new(cfg:TestPieceConfig):Void {
        super();

        this.cfg = cfg;

        stateAspectRequirements = [
            PieceAspect.PIECE_ID,
            PieceAspect.PIECE_REFLECTION,
            PieceAspect.PIECE_ROTATION,
        ];
    }

    override public function init(state:State):Void {
        super.init(state);
        var pieceID_:AspectPtr = state.stateAspectLookup[PieceAspect.PIECE_ID.id];
        state.aspects.mod(pieceID_, cfg.pieceID);

        var pieceReflection_:AspectPtr = state.stateAspectLookup[PieceAspect.PIECE_REFLECTION.id];
        state.aspects.mod(pieceReflection_, cfg.reflection);

        var pieceRotation_:AspectPtr = state.stateAspectLookup[PieceAspect.PIECE_ROTATION.id];
        state.aspects.mod(pieceRotation_, cfg.rotation);
    }
}
