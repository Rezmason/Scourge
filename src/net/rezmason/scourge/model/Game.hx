package net.rezmason.scourge.model;

import net.rezmason.ropes.RuleFactory;
import net.rezmason.ropes.State;
import net.rezmason.ropes.StatePlan;
import net.rezmason.ropes.StatePlanner;
import net.rezmason.ropes.StateHistorian;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.WinAspect;
import net.rezmason.utils.Zig;

using net.rezmason.scourge.model.BoardUtils;
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

    var historian:StateHistorian;
    var actions:Array<Rule>;
    var defaultActions:Array<Rule>;
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

    public function begin(config:ScourgeConfig, randomFunction:Void->Float, alertFunction:String->Void, savedState:SavedState = null):Int {

        if (hasBegun) {
            throw 'The game has already begun; it cannot begin again until you end it.';
        }

        var ruleAlertFunction = makeRuleAlertFunction(alertFunction);

        // Build the game from the config

        var ruleConfig:Map<String, Dynamic> = ScourgeConfigFactory.makeRuleConfig(config, randomFunction);
        var basicRulesByName:Map<String, Rule> = RuleFactory.makeBasicRules(ScourgeConfigFactory.ruleDefs, ruleConfig);

        if (cacheMoves) {
            for (key in basicRulesByName.keys().a2z()) {
                basicRulesByName[key] = RuleFactory.makeCacheRule(basicRulesByName[key], invalidateSignal, get_revision);
            }
        }

        var combinedConfig:Map<String, Array<String>> = ScourgeConfigFactory.makeCombinedRuleCfg(config);
        var combinedRules:Map<String, Rule> = RuleFactory.combineRules(combinedConfig, basicRulesByName);
        var builderRuleKeys:Array<String> = ScourgeConfigFactory.makeBuilderRuleList();
        var basicRules:Array<Rule> = [];
        var builderRules:Array<Rule> = [];
        for (key in basicRulesByName.keys().a2z()) {
            var builderRuleIndex:Int = builderRuleKeys.indexOf(key);
            if (builderRuleIndex == -1) basicRules.push(basicRulesByName[key]);
            else builderRules[builderRuleIndex] = basicRulesByName[key];
        }
        while (builderRules.remove(null)) {}

        // Plan the state

        plan = planner.planState(state, builderRules.concat(basicRules));

        for (rule in builderRules.concat(basicRules)) {
            rule.prime(state, plan, historian.history, historian.historyState, ruleAlertFunction);
        }

        // Grab some aspect pointers so we can quickly evaluate the state

        winner_ = plan.onGlobal(WinAspect.WINNER);
        currentPlayer_ = plan.onGlobal(PlyAspect.CURRENT_PLAYER);

        // Find the player actions

        actionIDs = ScourgeConfigFactory.makeActionList(config);
        actions = [];
        for (actionID in actionIDs) actions.push(combinedRules[actionID]);

        // Find the default actions

        var defaultActionIDs:Array<String> = ScourgeConfigFactory.makeDefaultActionList();
        defaultActions = [];
        for (defaultActionID in defaultActionIDs) defaultActions.push(combinedRules[defaultActionID]);

        // Find the start action and make it happen

        if (savedState != null) {
            historian.load(savedState);
        } else {
            historian.key.lock();
            var startAction = combinedRules[ScourgeConfigFactory.makeStartAction()];
            startAction.update();
            historian.key.unlock();
            startAction.chooseMove();
        }

        historian.write();
        historian.history.forget();

        return historian.history.revision;
    }

    public function save():SavedState { return historian.save(); }

    public function end():Void {

        if (!hasBegun)
            throw 'The game cannot end, because it hasn\'t begun.';

        historian.reset();
        invalidateSignal.removeAll();
        actions = null;
        actionIDs = null;
    }

    public function forget():Void { historian.history.forget(); }

    public function getMovesForAction(index:Int):Array<Move> {
        historian.key.lock();
        actions[index].update();
        var moves:Array<Move> = actions[index].moves;
        historian.key.unlock();
        return moves;
    }

    public function getQuantumMovesForAction(index:Int):Array<Move> {
        historian.key.lock();
        actions[index].update();
        var quantumMoves:Array<Move> = actions[index].quantumMoves;
        historian.key.unlock();
        return quantumMoves;
    }

    public function chooseMove(actionIndex:Int, moveIndex:Int = 0, isQuantum:Bool = false, cleanUp:Bool = true):Int {

        if (actionIndex < 0 || actionIndex > actionIDs.length - 1) throw 'Invalid action';

        if (isQuantum) {
            if (moveIndex < 0 || moveIndex > getQuantumMovesForAction(actionIndex).length - 1) {
                throw 'Invalid quantum move for action ${actionIDs[actionIndex]}';
            } else {
                actions[actionIndex].chooseQuantumMove(moveIndex);
            }
        } else {
            var numMovesForAction:Int = getMovesForAction(actionIndex).length - 1;
            if (moveIndex < 0) {
                throw 'Invalid move for action ${actionIDs[actionIndex]}: $moveIndex < 0';
            } else if (moveIndex > numMovesForAction) {
                throw 'Invalid move for action ${actionIDs[actionIndex]}: $moveIndex > $numMovesForAction';
            } else {
                actions[actionIndex].chooseMove(moveIndex);
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

    public function spitBoard():String return state.spitBoard(plan);

    public function spitMoves():String {
        var str:String = '';
        var moves:Array<Array<Move>> = [];
        for (ike in 0...actions.length) moves.push(getMovesForAction(ike));
        for (ike in 0...moves.length) {
            for (move in moves[ike]) {
                str += spitMove(ike, move) + ', \n';
            }
        }
        return '[\n${str}\n]';
    }

    public function spitMove(actionID:Int, move:Move):String {
        var str:String = 'actionID: $actionID, id: ${move.id}, ';
        var fields:Array<String> = Reflect.fields(move);
        for (field in fields.iterator().a2z()) str += '$field: ${Std.string(Reflect.field(move, field))}, ';
        return '{$str}';
    }

    private function pushHist():Int {
        historian.write();
        return historian.history.commit();
    }

    private function collectAllMoves():Void {
        historian.key.lock();
        for (action in actions) action.collectMoves();
        historian.key.unlock();
    }

    private function makeRuleAlertFunction(fn) return (fn == null) ? null : function(rule:Rule) fn(rule.myName());

    private function get_actionIDs():Array<String> { return actionIDs.copy(); }

    private function get_revision():Int { return historian.history.revision; }

    private function get_currentPlayer():Int { return historian.state.globals[currentPlayer_]; }

    private function get_winner():Int { return historian.state.globals[winner_]; }

    private function get_state():State { return historian.state; }

    private function get_hasBegun():Bool { return actions != null; }

    private function get_checksum():Int { return historian.history.getChecksum(); }
}
