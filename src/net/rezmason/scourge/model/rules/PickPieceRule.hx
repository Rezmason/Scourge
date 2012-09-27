package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.PieceAspect;

using net.rezmason.scourge.model.AspectUtils;
using net.rezmason.utils.Pointers;

typedef PickPieceConfig = {>BuildConfig,
    public var pieceTableIDs:Array<Int>; // The list of pieces available at any point in the game
    public var allowFlipping:Bool; // If false, the reflection is left to chance
    public var allowRotating:Bool; // If false, the rotation is left to chance
    public var allowAll:Bool; // if true, nothing is left to chance
    public var hatSize:Int; // Number of pieces in the "hat" before it's refilled
}

typedef PickPieceOption = {>Option,
    var hatIndex:Int;

    var pieceTableID:Int;
    var rotation:Int;
    var reflection:Int;
}

class PickPieceRule extends Rule {

    static var stateReqs:AspectRequirements;

    private var cfg:PickPieceConfig;

    @extra(PieceAspect.PIECE_HAT_NEXT) var pieceHatNext_:AspectPtr;
    @extra(PieceAspect.PIECE_HAT_PREV) var pieceHatPrev_:AspectPtr;
    @extra(PieceAspect.PIECE_ID) var pieceID_:AspectPtr;
    @extra(PieceAspect.PIECE_NEXT) var pieceNext_:AspectPtr;
    @extra(PieceAspect.PIECE_PREV) var piecePrev_:AspectPtr;

    @state(PieceAspect.PIECES_PICKED) var piecesPicked_:AspectPtr;
    @state(PieceAspect.PIECE_FIRST) var pieceFirst_:AspectPtr;
    @state(PieceAspect.PIECE_HAT_FIRST) var pieceHatFirst_:AspectPtr;
    @state(PieceAspect.PIECE_REFLECTION) var pieceReflection_:AspectPtr;
    @state(PieceAspect.PIECE_ROTATION) var pieceRotation_:AspectPtr;
    @state(PieceAspect.PIECE_TABLE_ID) var pieceTableID_:AspectPtr;

    var pieceOptions:Array<PickPieceOption>;
    var quantumPieceOptions:Array<PickPieceOption>;

    public function new(cfg:PickPieceConfig):Void {
        super();
        this.cfg = cfg;
        if (cfg.hatSize > cfg.pieceTableIDs.length) cfg.hatSize = cfg.pieceTableIDs.length;
    }

    override public function init(state:State, plan:StatePlan):Void {
        super.init(state, plan);
        buildPieces();
        if (!cfg.allowAll) buildHat();
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
        var chanceMultiplier:Int = cfg.pieceTableIDs.length;
        if (!cfg.allowRotating) chanceMultiplier *= 4;
        if (!cfg.allowFlipping) chanceMultiplier *= 2;

        var allPieces:Array<AspectSet> = [];
        for (ike in 0...chanceMultiplier) {
            extraAspectTemplate.mod(pieceID_, state.extras.length);
            var piece:AspectSet = buildExtra();
            allPieces.push(piece);
            state.extras.push(piece);
            cfg.historyState.extras.push(buildHistExtra(cfg.history));
        }

        allPieces.chainByAspect(pieceID_, pieceNext_, piecePrev_);
        state.aspects.mod(pieceFirst_, allPieces[0].at(pieceID_));
    }

    private function buildHat():Void {
        var firstPiece:AspectSet = state.extras[state.aspects.at(pieceFirst_)];
        var allPieces:Array<AspectSet> = firstPiece.listToArray(state.extras, pieceNext_);
        allPieces.chainByAspect(pieceID_, pieceHatNext_, pieceHatPrev_);
        state.aspects.mod(pieceHatFirst_, firstPiece.at(pieceID_));
        state.aspects.mod(piecesPicked_, 0);
    }
}
