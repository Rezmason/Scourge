package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.PieceAspect;

using net.rezmason.utils.Pointers;

typedef TestPieceConfig = {
    var piece:Int;
}

class TestPieceRule extends Rule {

    static var stateReqs:AspectRequirements;

    private var cfg:TestPieceConfig;

    public function new(cfg:TestPieceConfig):Void {
        super();

        this.cfg = cfg;

        if (stateReqs == null) stateReqs = [
            PieceAspect.PIECE_ID,
        ];
    }

    override public function init(state:State):Void {
        super.init(state);
        var pieceID_:AspectPtr = state.stateAspectLookup[PieceAspect.PIECE_ID.id];
        history.set(state.aspects.at(pieceID_), cfg.piece);
    }

    override public function listStateAspectRequirements():AspectRequirements { return stateReqs; }
}
