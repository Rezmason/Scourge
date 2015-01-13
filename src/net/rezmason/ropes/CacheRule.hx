package net.rezmason.ropes;

import net.rezmason.utils.Zig;
import net.rezmason.ropes.RopesTypes;

using net.rezmason.utils.MapUtils;

typedef CacheConfig = {
    var rule:Rule;
    var invalidateSignal:Zig<Int->Void>;
    var revGetter:Void->Int;
};

class CacheRule extends Rule {

    private var rule:Rule;
    private var cfg:CacheConfig;
    private var moveCache:Array<Array<Move>>;
    private var quantumMoveCache:Array<Array<Move>>;

    override public function _init(cfg:Dynamic):Void {
        this.cfg = cfg;
        rule = this.cfg.rule;
        this.cfg.invalidateSignal.add(invalidate);
        moveCache = [];
        quantumMoveCache = [];

        globalAspectRequirements.absorb(rule.globalAspectRequirements);
        playerAspectRequirements.absorb(rule.playerAspectRequirements);
        nodeAspectRequirements.absorb(rule.nodeAspectRequirements);
    }

    override public function _prime():Void rule.prime(state, plan, history, historyState, onSignal);

    override private function _update():Void {
        var rev:Int = cfg.revGetter();
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

