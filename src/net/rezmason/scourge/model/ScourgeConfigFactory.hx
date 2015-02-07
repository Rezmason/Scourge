package net.rezmason.scourge.model;

import haxe.ds.ArraySort;
import net.rezmason.ropes.CacheRule;
import net.rezmason.ropes.JointRule;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.scourge.model.ScourgeAction.*;

import net.rezmason.scourge.model.bite.*;
import net.rezmason.scourge.model.body.*;
import net.rezmason.scourge.model.build.*;
import net.rezmason.scourge.model.meta.*;
import net.rezmason.scourge.model.piece.*;

import net.rezmason.utils.Siphon;
import net.rezmason.utils.StringSort;
import net.rezmason.utils.Zig;

using Lambda;
using Type;
using net.rezmason.utils.MapUtils;

typedef ReplenishableConfig = { prop:AspectProperty, amount:Int, period:Int, maxAmount:Int, }

class ScourgeConfigFactory {

    inline static var CLEAN_UP:String = 'cleanUp';
    inline static var WRAP_UP:String = 'wrapUp';

    static var BUILD_BOARD:String        = Type.getClassName(BuildBoardRule);
    static var BUILD_PLAYERS:String      = Type.getClassName(BuildPlayersRule);
    static var BUILD_GLOBAL:String       = Type.getClassName(BuildGlobalRule);
    static var CAVITY:String             = Type.getClassName(CavityRule);
    static var DECAY:String              = Type.getClassName(DecayRule);
    static var DROP_PIECE:String         = Type.getClassName(DropPieceRule);
    static var EAT_CELLS:String          = Type.getClassName(EatCellsRule);
    static var END_TURN:String           = Type.getClassName(EndTurnRule);
    static var RESET_FRESHNESS:String    = Type.getClassName(ResetFreshnessRule);
    static var FORFEIT:String            = Type.getClassName(ForfeitRule);
    static var KILL_HEADLESS_BODY:String = Type.getClassName(KillHeadlessBodyRule);
    static var PICK_PIECE:String         = Type.getClassName(PickPieceRule);
    static var REPLENISH:String          = Type.getClassName(ReplenishRule);
    static var STALEMATE:String          = Type.getClassName(StalemateRule);
    static var ONE_LIVING_PLAYER:String  = Type.getClassName(OneLivingPlayerRule);
    static var BITE:String               = Type.getClassName(BiteRule);
    static var SWAP_PIECE:String         = Type.getClassName(SwapPieceRule);

    public static var ruleDefs(default, null):Map<String, Class<Rule>> = cast Siphon.getDefs(
        'net.rezmason.scourge.model', 'src', true, "Rule$"
    );

    public inline static function makeDefaultActionList():Array<String> return [DROP_ACTION, QUIT_ACTION];
    public inline static function makeStartAction():String return START_ACTION;
    public static function makeBuilderRuleList():Array<String> return [BUILD_GLOBAL, BUILD_PLAYERS, BUILD_BOARD];
    public static function makeActionList(config:ScourgeConfig):Array<String> {

        var actionList:Array<String> = [QUIT_ACTION, DROP_ACTION/*, PICK_ACTION*/];

        if (config.pieceParams.allowSwapping) actionList.push(SWAP_ACTION);
        if (config.biteParams.allowBiting) actionList.push(BITE_ACTION);

        return actionList;
    }

    public static function makeRuleConfig(config:ScourgeConfig):Map<String, Dynamic> {
        var ruleConfig:Map<String, Dynamic> = [
            BUILD_GLOBAL => config.buildParams,
            BUILD_PLAYERS => config.buildParams,
            BUILD_BOARD => config.buildParams,
            EAT_CELLS => config.bodyParams,
            DECAY => config.bodyParams,
            DROP_PIECE => config.pieceParams,
            REPLENISH => config.metaParams,

            END_TURN => null,
            RESET_FRESHNESS => null,
            FORFEIT => null,
            KILL_HEADLESS_BODY => null,
            ONE_LIVING_PLAYER => null,
        ];

        if (!config.pieceParams.allowAllPieces) ruleConfig.set(PICK_PIECE, config.pieceParams);
        if (config.bodyParams.includeCavities) ruleConfig.set(CAVITY, null);
        if (!config.pieceParams.allowAllPieces && config.pieceParams.allowSwapping) ruleConfig.set(SWAP_PIECE, config.pieceParams);
        if (config.biteParams.allowBiting) ruleConfig.set(BITE, config.biteParams);
        if (config.metaParams.maxSkips > 0) ruleConfig.set(STALEMATE, config.metaParams);

        return ruleConfig;
    }

    public static function makeCombinedRuleCfg(config:ScourgeConfig):Map<String, Array<String>> {

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

        return combinedRuleConfig;
    }

    // copied from rule factory

    public static function makeBasicRules(ruleDefs:Map<String, Class<Rule>>, cfg:Map<String, Dynamic>):Map<String, Rule> {
        var rules:Map<String, Rule> = new Map();
        if (cfg != null) {
            var cfgKeys:Array<String> = [];
            for (key in cfg.keys()) cfgKeys.push(key);
            ArraySort.sort(cfgKeys, StringSort.sort);
            for (key in cfgKeys) {
                //var ruleDef:Class<Rule> = cast ruleDefs[key].resolveClass();
                var ruleDef:Class<Rule> = ruleDefs[key];
                if (ruleDef == null) {
                    trace('Rule not found: $key');
                } else {
                    rules[key] = ruleDef.createInstance([]);
                    rules[key].init(cfg[key]);
                }
            }
        }
        return rules;
    }

    public static function makeCacheRule(rule:Rule, invalidateSignal:Zig<Int->Void>, revGetter:Void->Int):Rule {
        var cacheRule:CacheRule = new CacheRule();
        cacheRule.init({rule:rule, invalidateSignal:invalidateSignal, revGetter:revGetter});
        return cacheRule;
    }

    public static function combineRules(cfg:Map<String, Array<String>>, basicRules:Map<String, Rule>):Map<String, Rule> {
        var combinedRules:Map<String, Rule> = new Map();

        if (cfg != null) {

            var ruleStack:Array<String> = [];

            function makeJointRule(key:String):Rule {
                ruleStack.push(key);
                var rules:Array<Rule> = [];
                var ruleNames:Array<String> = cfg[key];
                for (ruleName in ruleNames) {
                    if (ruleName == key) trace('Joint rule $key cannot contain itself.');
                    else if (ruleStack.has(ruleName)) trace('Cyclical joint rule definition: $key and $ruleName');
                    else if (basicRules.isNotNull(ruleName)) rules.push(basicRules[ruleName]);
                    else if (combinedRules.isNotNull(ruleName)) rules.push(combinedRules[ruleName]);
                    else if (cfg.isNotNull(ruleName)) rules.push(makeJointRule(ruleName));
                    else trace('Rule not found: $ruleName');
                }
                var jointRule:Rule = new JointRule();
                jointRule.init(rules);
                combinedRules[key] = jointRule;
                ruleStack.pop();
                return jointRule;
            }

            var cfgKeys:Array<String> = [];
            for (key in cfg.keys()) cfgKeys.push(key);

            ArraySort.sort(cfgKeys, StringSort.sort);
            for (key in cfgKeys) {
                if (basicRules.isNotNull(key)) trace('Basic rule already exists with name: $key');
                else if (combinedRules.isNull(key)) makeJointRule(key);
            }
        }

        return combinedRules;
    }
}
