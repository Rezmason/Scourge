package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.PieceAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.SwapAspect;

using Lambda;

//using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class SwapPieceRule extends Rule {

    @player(SwapAspect.NUM_SWAPS) var numSwaps_:AspectPtr;
    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_:AspectPtr;
    @state(PieceAspect.PIECE_TABLE_ID) var pieceTableID_:AspectPtr;

    public function new():Void {
        super();
    }

    override public function update():Void {
        options = [];
        if (
                state.players[state.aspects.at(currentPlayer_)].at(NUM_SWAPS) > 0 &&
                state.aspects.at(pieceTableID_) != Aspect.NULL) {
            options.push({optionID:0});
        }
    }

    override public function chooseOption(choice:Int):Void {
        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var numSwaps:Int = state.players[currentPlayer].at(NUM_SWAPS);
        state.players[currentPlayer].mod(NUM_SWAPS, numSwaps - 1);
        state.aspects.mod(pieceTableID_, Aspect.NULL);
    }
}

