package net.rezmason.scourge.model;

import net.rezmason.ropes.JointRule;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.scourge.model.ScourgeAction.*;

import net.rezmason.scourge.model.bite.*;
import net.rezmason.scourge.model.body.*;
import net.rezmason.scourge.model.build.*;
import net.rezmason.scourge.model.meta.*;
import net.rezmason.scourge.model.piece.*;

import net.rezmason.utils.StringSort;
import net.rezmason.utils.Zig;

using Lambda;
using Type;
using net.rezmason.utils.Alphabetizer;

typedef ReplenishableConfig = { prop:AspectProperty, amount:Int, period:Int, maxAmount:Int, }

class ScourgeConfigFactory {

    inline static var CLEAN_UP:String = 'cleanUp';
    inline static var WRAP_UP:String = 'wrapUp';

    static var BITE:String               = 'bite';
    static var BUILD_BOARD:String        = 'buildBoard';
    static var BUILD_GLOBAL:String       = 'buildGlobal';
    static var BUILD_PLAYERS:String      = 'buildPlayers';
    static var CAVITY:String             = 'cavity';
    static var DECAY:String              = 'decay';
    static var DROP_PIECE:String         = 'drop';
    static var EAT_CELLS:String          = 'eatCells';
    static var END_TURN:String           = 'endTurn';
    static var FORFEIT:String            = 'forfeit';
    static var KILL_HEADLESS_BODY:String = 'killHeadlessBody';
    static var ONE_LIVING_PLAYER:String  = 'oneLivingPlayer';
    static var PICK_PIECE:String         = 'pick';
    static var REPLENISH:String          = 'replenish';
    static var RESET_FRESHNESS:String    = 'resetFreshness';
    static var STALEMATE:String          = 'stalemate';
    static var SWAP_PIECE:String         = 'swap';

    public inline static function makeDefaultActionList():Array<String> return [DROP_ACTION, QUIT_ACTION];
    public inline static function makeStartAction():String return START_ACTION;
    public static function makeBuilderRuleList():Array<String> return [BUILD_GLOBAL, BUILD_PLAYERS, BUILD_BOARD];
    public static function makeActionList(config:ScourgeConfig):Array<String> {

        var actionList:Array<String> = [QUIT_ACTION, DROP_ACTION];

        if (config.pieceParams.allowSwapping) actionList.push(SWAP_ACTION);
        if (config.biteParams.allowBiting) actionList.push(BITE_ACTION);

        return actionList;
    }

    public static function combineRules(config:ScourgeConfig, basicRules:Map<String, Rule>):Map<String, Rule> {

        var combinedRuleConfig:Map<String, Array<String>> = [
            CLEAN_UP => [DECAY, KILL_HEADLESS_BODY, ONE_LIVING_PLAYER, RESET_FRESHNESS],
            WRAP_UP  => [END_TURN, REPLENISH],

            START_ACTION => [CLEAN_UP],
            QUIT_ACTION  => [FORFEIT, CLEAN_UP, WRAP_UP],
            DROP_ACTION  => [DROP_PIECE, EAT_CELLS, CLEAN_UP, WRAP_UP],
        ];

        if (config.bodyParams.includeCavities) combinedRuleConfig[CLEAN_UP].insert(1, CAVITY);
        if (!config.pieceParams.allowAllPieces && config.pieceParams.allowSwapping) combinedRuleConfig[SWAP_ACTION] = [SWAP_PIECE, PICK_PIECE];
        if (config.biteParams.allowBiting) combinedRuleConfig[BITE_ACTION] = [BITE, CLEAN_UP];
        if (config.metaParams.maxSkips > 0) combinedRuleConfig[DROP_ACTION].push(STALEMATE);

        if (!config.pieceParams.allowAllPieces) {
            combinedRuleConfig[START_ACTION].push(PICK_PIECE);
            combinedRuleConfig[WRAP_UP].push(PICK_PIECE);
        }

        var combinedRules:Map<String, Rule> = new Map();

        var ruleStack:Array<String> = [];

        function makeJointRule(key:String):Rule {
            ruleStack.push(key);
            var rules:Array<Rule> = [];
            var ruleNames:Array<String> = combinedRuleConfig[key];
            for (ruleName in ruleNames) {
                if (ruleName == key) trace('Joint rule $key cannot contain itself.');
                else if (ruleStack.has(ruleName)) trace('Cyclical joint rule definition: $key and $ruleName');
                else if (basicRules[ruleName] != null) rules.push(basicRules[ruleName]);
                else if (combinedRules[ruleName] != null) rules.push(combinedRules[ruleName]);
                else if (combinedRuleConfig[ruleName] != null) rules.push(makeJointRule(ruleName));
                else trace('Rule not found: $ruleName');
            }
            var jointRule:Rule = new JointRule();
            jointRule.init(rules);
            combinedRules[key] = jointRule;
            ruleStack.pop();
            return jointRule;
        }

        for (key in combinedRuleConfig.keys().a2z()) {
            if (basicRules[key] != null) trace('Basic rule already exists with name: $key');
            else if (combinedRules[key] == null) makeJointRule(key);
        }

        return combinedRules;
    }
}
