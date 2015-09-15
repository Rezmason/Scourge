package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.state.State;
import net.rezmason.praxis.Reckoner;
import net.rezmason.utils.Zig;

class Rule<Params> implements IRule {

    public var isRandom(default, null):Bool;
    public var moves(default, null):Array<Move> = [{id:0}];
    public var primed(default, null):Bool;
    public var reckoners(default, null):Array<Reckoner>;

    var surveyor:Surveyor<Params>;
    var actor:Actor<Params>;
    var id:String;

    var revGetter:Void->Int;
    var moveCache:Array<Array<Move>>;
    var caching:Bool;
    
    public function new(id, ?surveyor, actor, isRandom) {
        this.id = id;
        this.surveyor = surveyor;
        this.actor = actor;
        this.isRandom = isRandom;
        reckoners = [actor];
        if (surveyor != null) reckoners.push(surveyor);
        primed = false;
        caching = false;
    }

    public function prime(state, plan, history, historyState, changeSignal:String->Void = null):Void {
        primed = true;
        if (surveyor != null) surveyor.prime(state, plan, history, historyState);
        if (changeSignal == null) changeSignal = function(_) {};
        actor.prime(state, plan, history, historyState, changeSignal.bind(id));
    }

    public function update():Void {
        if (caching) {
            var rev = revGetter();
            if (moveCache[rev] != null) {
                moves = moveCache[rev];
            } else {
                actor.update();
                moveCache[rev] = moves = actor.moves;
            }
        } else {
            actor.update();
            moves = actor.moves;
        }
    }

    public function chooseMove(index:Int = -1):Void {
        var defaultChoice:Bool = index == -1;
        if (defaultChoice) index = 0;

        if (moves == null || moves.length < index || moves[index] == null) {
            throw 'Invalid choice index.';
        }
        actor.chooseMove(moves[index]);
    }

    public function collectMoves():Void {
        if (caching) clearCache(0);
        actor.collectMoves();
    }

    public function cacheMoves(clearCacheSignal:Zig<Int->Void>, revGetter:Void->Int) {
        clearCacheSignal.add(clearCache);
        this.revGetter = revGetter;
        moveCache = [];
        caching = true;
    }

    function clearCache(rev:Int):Void moveCache = moveCache.splice(rev, moveCache.length);
}
