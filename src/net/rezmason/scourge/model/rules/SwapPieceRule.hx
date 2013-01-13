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
        for (player in eachPlayer()) player.mod(numSwaps_, cfg.startingSwaps);
    }

    // This rule basically zaps the current player's piece and takes away a swap.
    override private function _update():Void {
        options = [];
        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var numSwaps:Int = getPlayer(currentPlayer).at(numSwaps_);
        if (numSwaps > 0 && state.aspects.at(pieceTableID_) != Aspect.NULL) options.push({optionID:0});
    }

    override private function _chooseOption(choice:Int):Void {
                var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var numSwaps:Int = getPlayer(currentPlayer).at(numSwaps_);
        getPlayer(currentPlayer).mod(numSwaps_, numSwaps - 1);
        state.aspects.mod(pieceTableID_, Aspect.NULL);
    }
}

