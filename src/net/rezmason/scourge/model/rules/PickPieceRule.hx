package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.PieceAspect;

using net.rezmason.utils.Pointers;

typedef PickPieceConfig = {
    public var pieceIDs:Array<Int>; // The list of pieces available at any point in the game
    public var allowFlipping:Bool; // If false, the reflection is left to chance
    public var allowRotating:Bool; // If false, the rotation is left to chance
    public var allowAll:Bool; // if true, nothing is left to chance
    public var hatSize:Int; // Number of pieces in the "hat" before it's refilled
}

class PickPieceRule extends Rule {

    static var stateReqs:AspectRequirements;

    private var cfg:PickPieceConfig;

    var pieceID_:AspectPtr;
    var pieceReflection_:AspectPtr;
    var pieceRotation_:AspectPtr;

    public function new(cfg:TestPieceConfig):Void {
        super();

        this.cfg = cfg;

        stateAspectRequirements = [
            PieceAspect.PIECE_ID,
            PieceAspect.PIECE_REFLECTION,
            PieceAspect.PIECE_ROTATION,
        ];
    }

    override public function init(state:State, plan:StatePlan):Void {
        super.init(state, plan);

        pieceID_ = statePtr(PieceAspect.PIECE_ID);
        pieceReflection_ = statePtr(PieceAspect.PIECE_REFLECTION);
        pieceRotation_ = statePtr(PieceAspect.PIECE_ROTATION);
    }

    override public function update():Void {

    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

    }

    override public function chooseQuantumOption(choice:Int):Void {
        super.chooseQuantumOption(choice);
    }
}
