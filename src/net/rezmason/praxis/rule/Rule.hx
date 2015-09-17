package net.rezmason.praxis.rule;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.Reckoner;
import net.rezmason.utils.Zig;

class Rule<Params> implements IRule {

    public var isRandom(default, null):Bool;
    public var moves(default, null):Array<Move> = [{id:0}];
    public var primed(default, null):Bool;
    public var reckoners(default, null):Array<Reckoner>;
    public var id(default, null):String;
    
    var builder:Builder<Params>;
    var surveyor:Surveyor<Params>;
    var actor:Actor<Params>;

    var revGetter:Void->Int;
    var moveCache:Array<Array<Move>>;
    var caching:Bool;
    
    public function new(id, params:Params, ?builder, ?surveyor, ?actor, isRandom:Bool) {
        this.id = id;
        this.builder = builder;
        this.surveyor = surveyor;
        this.actor = actor;
        this.isRandom = isRandom;
        reckoners = [];
        for (element in [builder, surveyor, actor]) {
            if (element != null) {
                element.params = params;
                element.init();
                reckoners.push(element);
            }
        }
        primed = false;
        caching = false;
    }

    public function prime(state, plan, changeSignal:String->Void = null):Void {
        primed = true;
        if (actor != null) {
            if (changeSignal == null) changeSignal = function(_) {};
            actor.signalChange = changeSignal.bind(id);
        }
        for (element in [builder, surveyor, actor]) {
            if (element != null) {
                element.primePointers(state, plan);
                element.prime();
            }
        }
    }

    public function update():Void {
        if (surveyor == null) return;
        if (caching) {
            var rev = revGetter();
            if (moveCache[rev] != null) {
                moves = moveCache[rev];
            } else {
                surveyor.update();
                moveCache[rev] = moves = surveyor.moves;
            }
        } else {
            surveyor.update();
            moves = surveyor.moves;
        }
    }

    public function chooseMove(index:Int = -1):Void {
        if (actor == null) return;
        var defaultChoice:Bool = index == -1;
        if (defaultChoice) index = 0;

        if (moves == null || moves.length < index || moves[index] == null) {
            throw 'Invalid choice index.';
        }
        actor.chooseMove(moves[index]);
    }

    public function collectMoves():Void {
        if (surveyor == null) return;
        if (caching) clearCache(0);
        surveyor.collectMoves();
        moves = surveyor.moves;
    }

    public function cacheMoves(clearCacheSignal:Zig<Int->Void>, revGetter:Void->Int) {
        clearCacheSignal.add(clearCache);
        this.revGetter = revGetter;
        moveCache = [];
        caching = true;
    }

    function clearCache(rev:Int):Void moveCache = moveCache.splice(rev, moveCache.length);
}
