package net.rezmason.ropes;

import net.rezmason.ropes.CacheRule;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.aspect.PlyAspect;
import net.rezmason.ropes.aspect.WinAspect;
import net.rezmason.ropes.config.GameConfig;
import net.rezmason.ropes.state.*;
import net.rezmason.utils.Zig;

using net.rezmason.utils.Alphabetizer;
using net.rezmason.utils.Pointers;

class Game {

    public var actionIDs(get, null):Array<String>;
    public var revision(get, never):Int;
    public var currentPlayer(get, never):Int;
    public var winner(get, never):Int;
    public var state(get, null):State;
    public var plan(default, null):StatePlan;
    public var hasBegun(get, null):Bool;
    public var checksum(get, null):Int;

    var rules:Map<String, Rule>;
    var historian:StateHistorian;
    var defaultActionIDs:Array<String>;
    var winner_:AspectPtr;
    var currentPlayer_:AspectPtr;
    var planner:StatePlanner;
    var cacheMoves:Bool;
    var invalidateSignal:Zig<Int->Void>;

    public function new(cacheMoves:Bool):Void {
        this.cacheMoves = cacheMoves;
        historian = new StateHistorian();
        planner = new StatePlanner();
        invalidateSignal = new Zig();
    }

    public function begin(config:GameConfig<Dynamic, Dynamic>, randomFunction:Void->Float, alertFunction:String->Void, savedState:SavedState = null):Int {

        if (hasBegun) {
            throw 'The game has already begun; it cannot begin again until you end it.';
        }

        var ruleAlertFunction = makeRuleAlertFunction(alertFunction);

        rules = config.makeRules(cacheMoves ? makeCacheRule : null);
        actionIDs = config.actionIDs;
        defaultActionIDs = config.defaultActionIDs;
        plan = planner.planState(state, rules);
        primeRule(rules['build'], randomFunction, ruleAlertFunction);
        for (key in rules.keys().a2z()) {
            if (!rules[key].primed) primeRule(rules[key], randomFunction, ruleAlertFunction);
        }

        // Grab some aspect pointers so we can quickly evaluate the state

        winner_ = plan.onGlobal(WinAspect.WINNER);
        currentPlayer_ = plan.onGlobal(PlyAspect.CURRENT_PLAYER);

        // Find the start action and make it happen

        if (savedState != null) {
            historian.load(savedState);
        } else {
            historian.key.lock();
            var startAction = rules['start'];
            startAction.update();
            historian.key.unlock();
            startAction.chooseMove();
        }

        historian.write();
        historian.history.forget();

        return historian.history.revision;
    }

    function primeRule(rule, randomFunction, alertFunction) {
        rule.prime(state, plan, historian.history, historian.historyState, randomFunction, alertFunction);
    }

    public function save():SavedState { return historian.save(); }

    public function end():Void {

        if (!hasBegun)
            throw 'The game cannot end, because it hasn\'t begun.';

        historian.reset();
        invalidateSignal.removeAll();
        rules = null;
        actionIDs = null;
        defaultActionIDs = null;
    }

    public function forget():Void { historian.history.forget(); }

    public function getMovesForAction(id:String):Array<Move> {
        if (actionIDs.indexOf(id) == -1) throw 'Action $id does not exist.';
        historian.key.lock();
        rules[id].update();
        var moves:Array<Move> = rules[id].moves;
        historian.key.unlock();
        return moves;
    }

    public function getQuantumMovesForAction(id:String):Array<Move> {
        if (actionIDs.indexOf(id) == -1) throw 'Action $id does not exist.';
        historian.key.lock();
        rules[id].update();
        var quantumMoves:Array<Move> = rules[id].quantumMoves;
        historian.key.unlock();
        return quantumMoves;
    }

    public function chooseMove(actionID:String, moveIndex:Int = 0, isQuantum:Bool = false, cleanUp:Bool = true):Int {

        if (actionIDs.indexOf(actionID) == -1) throw 'Action $actionID does not exist.';

        if (isQuantum) {
            if (moveIndex < 0 || moveIndex > getQuantumMovesForAction(actionID).length - 1) {
                throw 'Invalid quantum move for action $actionID}';
            } else {
                rules[actionID].chooseQuantumMove(moveIndex);
            }
        } else {
            var numMovesForAction:Int = getMovesForAction(actionID).length - 1;
            if (moveIndex < 0) {
                throw 'Invalid move for action $actionID: $moveIndex < 0';
            } else if (moveIndex > numMovesForAction) {
                throw 'Invalid move for action $actionID: $moveIndex > $numMovesForAction';
            } else {
                rules[actionID].chooseMove(moveIndex);
            }
        }

        pushHist();
        if (cleanUp) {
            collectAllMoves();
            invalidateSignal.dispatch(revision);
        }
        return revision;
    }

    public function rewind(revision:Int):Void {
        historian.history.revert(revision);
        historian.read();
        invalidateSignal.dispatch(revision);
    }

    private function pushHist():Int {
        historian.write();
        return historian.history.commit();
    }

    private function collectAllMoves():Void {
        historian.key.lock();
        for (id in actionIDs) rules[id].collectMoves();
        historian.key.unlock();
    }

    private function makeCacheRule(rule:Rule):Rule {
        var cacheRule:CacheRule = new CacheRule();
        cacheRule.init({rule:rule, invalidateSignal:invalidateSignal, revGetter:get_revision});
        return cacheRule;
    }

    private function makeRuleAlertFunction(fn) return (fn == null) ? null : function(rule:Rule) fn(rule.myName());

    private function get_actionIDs():Array<String> { return actionIDs.copy(); }

    private function get_revision():Int { return historian.history.revision; }

    private function get_currentPlayer():Int { return historian.state.global[currentPlayer_]; }

    private function get_winner():Int { return historian.state.global[winner_]; }

    private function get_state():State { return historian.state; }

    private function get_hasBegun():Bool { return rules != null; }

    private function get_checksum():Int { return historian.history.getChecksum(); }
}
