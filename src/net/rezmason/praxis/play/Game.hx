package net.rezmason.praxis.play;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.aspect.PlyAspect;
import net.rezmason.praxis.aspect.WinAspect;
import net.rezmason.praxis.config.GameConfig;
import net.rezmason.praxis.rule.IRule;
import net.rezmason.praxis.state.*;
import net.rezmason.utils.Zig;

using net.rezmason.utils.Alphabetizer;
using net.rezmason.utils.pointers.Pointers;

class Game {

    public var actionIDs(get, null):Array<String>;
    public var revision(get, never):Int;
    public var currentPlayer(get, never):Int;
    public var winner(get, never):Int;
    public var state(get, null):State;
    public var plan(default, null):StatePlan;
    public var hasBegun(get, null):Bool;
    public var checksum(get, null):Int;

    var rules:Map<String, IRule>;
    var historian:StateHistorian;
    var defaultActionIDs:Array<String>;
    var winner_:AspectPointer<PGlobal>;
    var currentPlayer_:AspectPointer<PGlobal>;
    var planner:StatePlanner;
    var cacheMoves:Bool;
    var clearCacheSignal:Zig<Int->Void>;

    public function new(cacheMoves:Bool):Void {
        this.cacheMoves = cacheMoves;
        historian = new StateHistorian();
        planner = new StatePlanner();
        clearCacheSignal = new Zig();
    }

    public function begin(config:GameConfig<Dynamic, Dynamic>, alertFunction:String->Void, savedState:SavedState = null):Int {

        if (hasBegun) {
            throw 'The game has already begun; it cannot begin again until you end it.';
        }

        rules = config.makeRules();
        if (cacheMoves) for (rule in rules) rule.cacheMoves(clearCacheSignal, get_revision);
        actionIDs = config.actionIDs;
        defaultActionIDs = config.defaultActionIDs;
        plan = planner.planState(state, rules);
        primeRule('build', alertFunction);
        for (id in rules.keys().a2z()) if (!rules[id].primed) primeRule(id, alertFunction);

        // Grab some aspect pointers so we can quickly evaluate the state

        winner_ = plan.onGlobal(WinAspect.WINNER);
        currentPlayer_ = plan.onGlobal(PlyAspect.CURRENT_PLAYER);

        // Find the start action and make it happen

        if (savedState != null) {
            historian.load(savedState);
        } else {
            var startAction = rules['start'];
            startAction.update();
            startAction.chooseMove();
        }

        historian.write();
        historian.history.forget();

        return historian.history.revision;
    }

    inline function primeRule(id:String, alertFunction:String->Void) {
        rules[id].prime(state, plan, historian.history, historian.historyState, alertFunction);
    }

    public function save():SavedState { return historian.save(); }

    public function end():Void {

        if (!hasBegun)
            throw 'The game cannot end, because it hasn\'t begun.';

        historian.reset();
        clearCacheSignal.removeAll();
        rules = null;
        actionIDs = null;
        defaultActionIDs = null;
    }

    public function forget():Void { historian.history.forget(); }

    public inline function isRuleRandom(id):Bool return rules[id] != null && rules[id].isRandom;

    public function getMovesForAction(id:String):Array<Move> {
        if (actionIDs.indexOf(id) == -1) throw 'Action $id does not exist.';
        rules[id].update();
        var moves:Array<Move> = rules[id].moves;
        return moves;
    }

    public function chooseMove(actionID:String, moveIndex:Int = 0, cleanUp:Bool = true):Int {

        if (actionIDs.indexOf(actionID) == -1) throw 'Action $actionID does not exist.';
        var numMovesForAction:Int = getMovesForAction(actionID).length;
        if (moveIndex < 0) throw 'Invalid move for action $actionID: $moveIndex < 0';
        if (moveIndex >= numMovesForAction) throw 'Invalid move for action $actionID: $moveIndex >= $numMovesForAction';
        rules[actionID].chooseMove(moveIndex);

        pushHist();
        if (cleanUp) {
            collectAllMoves();
            clearCacheSignal.dispatch(revision);
        }
        return revision;
    }

    public function rewind(revision:Int):Void {
        historian.history.revert(revision);
        historian.read();
        clearCacheSignal.dispatch(revision);
    }

    private function pushHist():Int {
        historian.write();
        return historian.history.commit();
    }

    private function collectAllMoves():Void {
        for (id in actionIDs) rules[id].collectMoves();
    }

    private function get_actionIDs():Array<String> { return actionIDs.copy(); }

    private function get_revision():Int { return historian.history.revision; }

    private function get_currentPlayer():Int { return historian.state.global[currentPlayer_]; }

    private function get_winner():Int { return historian.state.global[winner_]; }

    private function get_state():State { return historian.state; }

    private function get_hasBegun():Bool { return rules != null; }

    private function get_checksum():Int { return historian.history.getChecksum(); }
}
