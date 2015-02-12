package net.rezmason.ropes.rule;

import net.rezmason.utils.Zig;
import net.rezmason.ropes.RopesTypes;

using net.rezmason.utils.MapUtils;

typedef CacheParams = {
    var rule:Rule;
    var invalidateSignal:Zig<Int->Void>;
    var revGetter:Void->Int;
};

class CacheRule extends BaseRule<CacheParams> {

    private var rule:Rule;
    private var moveCache:Array<Array<Move>> = [];
    private var quantumMoveCache:Array<Array<Move>> = [];

    override public function _init():Void {
        rule = params.rule;
        params.invalidateSignal.add(invalidate);

        globalAspectRequirements.absorb(rule.globalAspectRequirements);
        playerAspectRequirements.absorb(rule.playerAspectRequirements);
        nodeAspectRequirements.absorb(rule.nodeAspectRequirements);
    }

    override public function _prime():Void rule.prime(state, plan, history, historyState, random, changeSignal);

    override private function _update():Void {
        var rev:Int = params.revGetter();
        if (moveCache[rev] != null) {
            #if ROPES_VERBOSE trace('Cached: $rule $rev'); #end
            rule.moves = moves = moveCache[rev];
            rule.quantumMoves = quantumMoves = quantumMoveCache[rev];
        }
        else {
            #if ROPES_VERBOSE trace('Not cached: $rule $rev'); #end
            rule.update();
            moveCache[rev] = moves = rule.moves;
            quantumMoveCache[rev] = quantumMoves = rule.quantumMoves;
        }
    }

    override private function _chooseMove(choice:Int):Void {
        #if ROPES_VERBOSE trace('<'); #end
        rule.chooseMove(choice);
        #if ROPES_VERBOSE trace('>'); #end
    }

    override private function _collectMoves():Void {
        invalidate(0);
        rule.collectMoves();
    }

    override private function _chooseQuantumMove(choice:Int):Void {
        #if ROPES_VERBOSE trace('<'); #end
        rule.chooseQuantumMove(choice);
        #if ROPES_VERBOSE trace('>'); #end
    }

    function invalidate(rev:Int):Void {
        moveCache = moveCache.splice(rev, moveCache.length);
        quantumMoveCache = quantumMoveCache.splice(rev, quantumMoveCache.length);
    }
}

