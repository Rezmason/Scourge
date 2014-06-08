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
    
    override public function init(game:Game, config:ScourgeConfig):Void {
        super.init(game, config);
        dropActionIndex = game.actionIDs.indexOf(DROP_ACTION);
        swapActionIndex = game.actionIDs.indexOf(SWAP_ACTION);
        biteActionIndex = game.actionIDs.indexOf(BITE_ACTION);
        quitActionIndex = game.actionIDs.indexOf(QUIT_ACTION);
        canSkip = config.allowNowhereDrop;

        totalArea_ = game.plan.onPlayer(BodyAspect.TOTAL_AREA);
        occupier_ = game.plan.onNode(OwnershipAspect.OCCUPIER);
    }

    override public function choose(game:Game):GameEventType {
        var type:GameEventType = null;
        var rev:Int = game.revision;

        var dropMoves:Array<Move> = game.getMovesForAction(dropActionIndex);
        var choice:Int = 0;
        
        if (type == null) {
            var canDrop:Bool = dropMoves.length > (canSkip ? 1 : 0);
            if (canDrop) {
                choice = random(dropMoves.length - (canSkip ? 1 : 0));
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

                var biteSizes:Array<Int> = biteMoves.map(function(_) return (cast _).bitNodes.length);
                var maxBiteSize:Int = biteSizes[biteSizes.length - 1];
                var maxBiteSizeIndex:Int = biteSizes.indexOf(maxBiteSize);

                var maxReduction:Int = 0;
                var maxReductionIndex:Int = 0;
                var players = game.state.players;
                var nodes = game.state.nodes;
                var itr:Int = 0;
                for (ike in maxBiteSizeIndex...biteMoves.length) {
                    var enemy = players[nodes[(cast biteMoves[ike]).bitNodes[0]][occupier_]];
                    var enemySize:Int = enemy[totalArea_];
                    game.chooseMove(biteActionIndex, ike);
                    var reduction:Int = enemySize - enemy[totalArea_];
                    game.rewind(rev);
                    if (maxReduction < reduction) {
                        maxReduction = reduction;
                        maxReductionIndex = ike;
                    }
                    itr++;
                }
                
                choice = maxReductionIndex;
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
}
