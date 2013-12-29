package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Rule;

import net.rezmason.scourge.model.aspects.PieceAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.SwapAspect;

using Lambda;

using net.rezmason.utils.Pointers;

typedef SwapPieceConfig = {
    var startingSwaps:Int;
}

class SwapPieceRule extends Rule {

    @player(SwapAspect.NUM_SWAPS) var numSwaps_;
    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_;
    @state(PieceAspect.PIECE_TABLE_ID) var pieceTableID_;

    var cfg:SwapPieceConfig;

    public function new(cfg:SwapPieceConfig):Void {
        super();
        this.cfg = cfg;
    }

    override private function _prime():Void {
        for (player in eachPlayer()) player[numSwaps_] = cfg.startingSwaps;
    }

    // This rule basically zaps the current player's piece and takes away a swap.
    override private function _update():Void {
        moves = [];
        var currentPlayer:Int = state.aspects[currentPlayer_];
        var numSwaps:Int = getPlayer(currentPlayer)[numSwaps_];
        if (numSwaps > 0 && state.aspects[pieceTableID_] != Aspect.NULL) moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {
                var currentPlayer:Int = state.aspects[currentPlayer_];
        var numSwaps:Int = getPlayer(currentPlayer)[numSwaps_];
        getPlayer(currentPlayer)[numSwaps_] = numSwaps - 1;
        state.aspects[pieceTableID_] = Aspect.NULL;
        signalEvent();
    }
}

