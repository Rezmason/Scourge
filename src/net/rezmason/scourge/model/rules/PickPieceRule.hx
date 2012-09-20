package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.PieceAspect;
import net.rezmason.scourge.model.rules.BuildRule;

using net.rezmason.utils.Pointers;

typedef PickPieceConfig = {>BuildConfig,
    public var pieceIDs:Array<Int>; // The list of pieces available at any point in the game
    public var allowFlipping:Bool; // If false, the reflection is left to chance
    public var allowRotating:Bool; // If false, the rotation is left to chance
    public var allowAll:Bool; // if true, nothing is left to chance
    public var hatSize:Int; // Number of pieces in the "hat" before it's refilled
}

class PickPieceRule extends BuildRule {

    static var stateReqs:AspectRequirements;

    private var cfg:PickPieceConfig;

    var pieceID_:AspectPtr;
    var piecesPicked_:AspectPtr;
    var pieceReflection_:AspectPtr;
    var pieceRotation_:AspectPtr;

    var pieceFirst_:AspectPtr;
    var pieceNext_:AspectPtr;
    var pieceHatFirst_:AspectPtr;
    var pieceHatNext_:AspectPtr;

    public function new(cfg:PickPieceConfig):Void {
        super();

        this.cfg = cfg;

        stateAspectRequirements = [
            PieceAspect.PIECE_ID,
            PieceAspect.PIECES_PICKED,
            PieceAspect.PIECE_REFLECTION,
            PieceAspect.PIECE_ROTATION,
            PieceAspect.PIECE_FIRST,
            PieceAspect.PIECE_HAT_FIRST,
        ];

        extraAspectRequirements = [
            PieceAspect.PIECE_ID,
            PieceAspect.PIECE_NEXT,
            PieceAspect.PIECE_HAT_NEXT,
        ];
    }

    override public function init(state:State, plan:StatePlan):Void {
        super.init(state, plan);

        pieceID_ = statePtr(PieceAspect.PIECE_ID);
        pieceReflection_ = statePtr(PieceAspect.PIECE_REFLECTION);
        pieceRotation_ = statePtr(PieceAspect.PIECE_ROTATION);

        buildPieces();

    }

    override public function update():Void {

    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

    }

    override public function chooseQuantumOption(choice:Int):Void {
        super.chooseQuantumOption(choice);

    }

    private function buildPieces():Void {
        var allPieces:Array<AspectSet> = [];
        for (id in cfg.pieceIDs) {
            var piece:AspectSet = buildExtra();
            allPieces.push(piece);
            state.extras.push(piece);
            cfg.historyState.extras.push(buildHistExtra(cfg.history));
        }

        for (piece in allPieces) {
            // link them together
        }
    }
}
