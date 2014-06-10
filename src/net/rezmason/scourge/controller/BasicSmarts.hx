package net.rezmason.scourge.controller;

import Std.random;

import net.rezmason.ropes.RopesTypes.Move;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeAction.*;
import net.rezmason.scourge.model.ScourgeConfig;

import net.rezmason.ropes.RopesTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using net.rezmason.ropes.StatePlan;

class BasicSmarts extends Smarts {

    private var dropActionIndex:Int;
    private var swapActionIndex:Int;
    private var biteActionIndex:Int;
    private var quitActionIndex:Int;
    private var otherActionIndices:Array<Int>;
    private var canSkip:Bool;
    private var totalArea_:AspectPtr;
    private var occupier_:AspectPtr;
    
    override public function init(game:Game, config:ScourgeConfig, id:Int):Void {
        super.init(game, config, id);
        dropActionIndex = game.actionIDs.indexOf(DROP_ACTION);
        swapActionIndex = game.actionIDs.indexOf(SWAP_ACTION);
        biteActionIndex = game.actionIDs.indexOf(BITE_ACTION);
        quitActionIndex = game.actionIDs.indexOf(QUIT_ACTION);
        canSkip = config.allowNowhereDrop;

        totalArea_ = game.plan.onPlayer(BodyAspect.TOTAL_AREA);
        occupier_ = game.plan.onNode(OwnershipAspect.OCCUPIER);
    }

    override public function choose():GameEventType {
        var type:GameEventType = null;
        
        var dropMoves:Array<Move> = game.getMovesForAction(dropActionIndex);
        var choice:Int = 0;
        var numSkipMoves:Int = canSkip ? 1 : 0;
        
        if (type == null) {
            var canDrop:Bool = dropMoves.length > numSkipMoves;
            if (canDrop) {
                choice = numSkipMoves + random(dropMoves.length - numSkipMoves);
                // Too expensive without pruning
                // choice = findBestMoveIndex(dropActionIndex, numSkipMoves, dropMoves.length, getEnemySize);
                type = PlayerAction(SubmitMove(dropActionIndex, choice));
            }
        }

        if (type == null) {
            var swapMoves:Array<Move> = game.getMovesForAction(swapActionIndex);
            if (swapMoves.length > 0) {
                choice = random(swapMoves.length);
                type = PlayerAction(SubmitMove(swapActionIndex, choice));
            }
        }

        if (type == null) {
            var biteMoves:Array<Move> = game.getMovesForAction(biteActionIndex);
            if (biteMoves.length > 0) {
                // pruning
                var biteSizes:Array<Int> = biteMoves.map(function(_) return (cast _).bitNodes.length);
                var maxBiteSize:Int = biteSizes[biteSizes.length - 1];
                var maxBiteSizeIndex:Int = biteSizes.indexOf(maxBiteSize);
                
                choice = findBestMoveIndex(biteActionIndex, maxBiteSizeIndex, biteMoves.length, getEnemySize);
                type = PlayerAction(SubmitMove(biteActionIndex, choice));
            }
        }

        if (type == null) {
            if (canSkip) {
                type = PlayerAction(SubmitMove(dropActionIndex, choice));
            }
        }

        if (type == null) {
            var quitMoves:Array<Move> = game.getMovesForAction(quitActionIndex);
            if (quitMoves.length > 0) {
                type = PlayerAction(SubmitMove(quitActionIndex, choice));
            }
        }

        return type;
    }

    function getEnemySize():Int {
        var sum:Int = 0;
        for (ike in 0...game.state.players.length) if (ike != id) sum += game.state.players[ike][totalArea_];
        return sum;
    }

    function findBestMoveIndex(actionIndex:Int, start:Int, end:Int, eval:Void->Int, invert:Bool = false):Int {
        var extreme:Int = 0;
        var index:Int = 0;
        for (ike in start...end) {
            var rev:Int = game.revision;
            game.chooseMove(actionIndex, ike);
            var value:Int = eval();
            game.rewind(rev);
            if (extreme > value != invert) {
                extreme = value;
                index = ike;
            }
        }
        return index;
    }
}
