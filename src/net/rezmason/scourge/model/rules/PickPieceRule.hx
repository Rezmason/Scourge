package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.PieceAspect;

using net.rezmason.scourge.model.AspectUtils;
using net.rezmason.utils.Pointers;

typedef PickPieceConfig = {>BuildConfig,
    public var pieceIDs:Array<Int>; // The list of pieces available at any point in the game
    public var allowFlipping:Bool; // If false, the reflection is left to chance
    public var allowRotating:Bool; // If false, the rotation is left to chance
    public var allowAll:Bool; // if true, nothing is left to chance
    public var hatSize:Int; // Number of pieces in the "hat" before it's refilled
}

class PickPieceRule extends Rule {

    static var stateReqs:AspectRequirements;

    private var cfg:PickPieceConfig;

    @requireExtra(PieceAspect.PIECE_HAT_NEXT) var pieceHatNext_:AspectPtr;
    @requireExtra(PieceAspect.PIECE_ID) var pieceID_:AspectPtr;
    @requireExtra(PieceAspect.PIECE_NEXT) var pieceNext_:AspectPtr;
    @requireState(PieceAspect.PIECES_PICKED) var piecesPicked_:AspectPtr;
    @requireState(PieceAspect.PIECE_FIRST) var pieceFirst_:AspectPtr;
    @requireState(PieceAspect.PIECE_HAT_FIRST) var pieceHatFirst_:AspectPtr;
    @requireState(PieceAspect.PIECE_REFLECTION) var pieceReflection_:AspectPtr;
    @requireState(PieceAspect.PIECE_ROTATION) var pieceRotation_:AspectPtr;
    @requireState(PieceAspect.PIECE_TABLE_ID) var pieceTableID_:AspectPtr;

    public function new(cfg:PickPieceConfig):Void {
        super();
        this.cfg = cfg;
    }

    override public function init(state:State, plan:StatePlan):Void {
        super.init(state, plan);
        buildPieces();
    }

    override public function update():Void {
        /*
        piece = state.piece
        state = state.picked
        if piece == NULL || picked >= cfg.hatSize
            state.firstHat = state.firstPiece
            piece = state.firstPiece
            while (piece != null)
                piece.nextHat = piece.nextPiece
                piece = piece.nextPiece
            state.picked = 0

        rand = random(0-cfg.pieces.length)
        piece = pieces[rand]
        removeNode... SHIT
        */
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
