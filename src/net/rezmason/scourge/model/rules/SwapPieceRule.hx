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

    override public function init():Void {
        for (player in state.players) player.mod(numSwaps_, cfg.startingSwaps);
    }

    // This rule basically zaps the current player's piece and takes away a swap.
    override public function update():Void {
        options = [];
        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var numSwaps:Int = state.players[currentPlayer].at(numSwaps_);
        if (numSwaps > 0 && state.aspects.at(pieceTableID_) != Aspect.NULL) options.push({optionID:0});
    }

    override public function chooseOption(choice:Int = 0):Void {
        super.chooseOption(choice);
        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var numSwaps:Int = state.players[currentPlayer].at(numSwaps_);
        state.players[currentPlayer].mod(numSwaps_, numSwaps - 1);
        state.aspects.mod(pieceTableID_, Aspect.NULL);
    }
}

