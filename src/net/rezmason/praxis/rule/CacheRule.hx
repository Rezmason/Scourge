package net.rezmason.praxis.rule;

import net.rezmason.utils.Zig;
import net.rezmason.praxis.PraxisTypes;

using net.rezmason.utils.MapUtils;

typedef CacheParams = {
    var rule:Rule;
    var invalidateSignal:Zig<Int->Void>;
    var revGetter:Void->Int;
};

class CacheRule extends BaseRule<CacheParams> {

    private var rule:Rule;
    private var moveCache:Array<Array<Move>> = [];

    override public function _init():Void {
        rule = params.rule;
        this.isRandom = rule.isRandom;
        params.invalidateSignal.add(invalidate);

        globalAspectRequirements.absorb(rule.globalAspectRequirements);
        playerAspectRequirements.absorb(rule.playerAspectRequirements);
        nodeAspectRequirements.absorb(rule.nodeAspectRequirements);
    }

    override public function _prime():Void rule.prime(state, plan, history, historyState, changeSignal);

    override private function _update():Void {
        var rev:Int = params.revGetter();
        if (moveCache[rev] != null) {
            #if ROPES_VERBOSE trace('Cached: $rule $rev'); #end
            rule.moves = moves = moveCache[rev];
        }
        else {
            #if ROPES_VERBOSE trace('Not cached: $rule $rev'); #end
            rule.update();
            moveCache[rev] = moves = rule.moves;
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

    function invalidate(rev:Int):Void moveCache = moveCache.splice(rev, moveCache.length);
}

