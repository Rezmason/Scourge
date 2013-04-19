package net.rezmason.scourge.model;

import net.rezmason.scourge.model.BuildConfig;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.Rule;
import net.rezmason.ropes.State;
import net.rezmason.utils.Siphon;
import net.rezmason.scourge.model.aspects.BiteAspect;
import net.rezmason.scourge.model.aspects.SwapAspect;
import net.rezmason.scourge.model.Pieces;

typedef ReplenishableConfig = { prop:AspectProperty, amount:Int, period:Int, maxAmount:Int, }

class ScourgeConfigFactory {

    public static var ruleDefs:Map<String, Class<Rule>> = cast Siphon.getDefs("net.rezmason.scourge.model.rules", "src", "Rule");

    public static function makeDefaultActionList():Array<String> { return ["dropAction", "quitAction"]; }
    public static function makeStartAction():String { return "startAction"; }
    public static function makeDemiurgicRuleList():Array<String> { return ["BuildStateRule", "BuildPlayersRule", "BuildBoardRule"]; }
    public static function makeActionList(config:ScourgeConfig):Array<String> {

        var actionList:Array<String> = ["quitAction", "dropAction", "pickPieceAction"];

        if (config.maxSwaps > 0) actionList.push("swapAction");
        if (config.maxBites > 0) actionList.push("biteAction");

        return actionList;
    }

    public static function makeDefaultConfig():ScourgeConfig {
        return {
            allowAllPieces:false,
            allowFlipping:false,
            allowNowhereDrop:true,
            allowRotating:true,
            baseBiteReachOnThickness:false,
            biteHeads:true,
            biteThroughCavities:false,
            circular:false,
            diagDropOnly:false,
            eatHeads:true,
            eatRecursive:true,
            growGraphWithDrop:false,
            includeCavities:true,
            omnidirectionalBite:false,
            orthoBiteOnly:true,
            orthoDecayOnly:true,
            orthoDropOnly:true,
            orthoEatOnly:false,
            overlapSelf:false,
            takeBodiesFromHeads:true,
            firstPlayer:0,
            maxBiteReach:3,
            maxSizeReference:Std.int(400 * 0.7),
            minBiteReach:1,
            numPlayers:4,
            pieceHatSize:5,
            startingSwaps:5,
            startingBites:5,
            swapBoost:1,
            swapPeriod:4,
            maxSwaps:10,
            biteBoost:1,
            bitePeriod:3,
            maxBites:10,
            maxSkips:3,
            initGrid:null,
            pieceTableIDs:Pieces.getAllPieceIDsOfSize(4),
        };
    }

    public static function makeRuleConfig(config:ScourgeConfig, randomFunction:Void->Float, history:StateHistory, historyState:State):Dynamic {
        var buildCfg:BuildConfig = makeBuildConfig(history, historyState);

        var ruleConfig:Dynamic = {
            BuildStateRule: makeBuildStateConfig(config, buildCfg),
            BuildPlayersRule: makeBuildPlayersConfig(config, buildCfg),
            BuildBoardRule: makeBuildBoardConfig(config, buildCfg),
            EatCellsRule: makeEatCellsConfig(config),
            DecayRule: makeDecayConfig(config),
            PickPieceRule: makePickPieceConfig(config, buildCfg, randomFunction),
            DropPieceRule: makeDropPieceConfig(config),
            ReplenishRule: makeReplenishConfig(config, buildCfg),
            SkipsExhaustedRule: makeSkipsExhaustedConfig(config),

            EndTurnRule: null,
            ForfeitRule: null,
            KillHeadlessPlayerRule: null,
            OneLivingPlayerRule: null,

            //SpitBoardRule: null,
        };

        if (config.includeCavities) ruleConfig.CavityRule = null;
        if (config.maxSwaps > 0) ruleConfig.SwapPieceRule = makeSwapConfig(config);
        if (config.maxBites > 0) ruleConfig.BiteRule = makeBiteConfig(config);

        return ruleConfig;
    }

    public static function makeCombinedRuleCfg(config:ScourgeConfig):Dynamic<Array<String>> {
        var combinedRuleConfig:Dynamic<Array<String>> = {
            cleanUp: ["DecayRule", "KillHeadlessPlayerRule", "OneLivingPlayerRule"],
            wrapUp: ["EndTurnRule", "ReplenishRule"],

            pickPieceAction: ["PickPieceRule"],
            startAction: ["cleanUp"],
            quitAction: ["ForfeitRule", "cleanUp", "wrapUp"],
            dropAction: ["DropPieceRule", "EatCellsRule", "cleanUp", "wrapUp", "SkipsExhaustedRule"],
        };

        if (config.includeCavities) combinedRuleConfig.cleanUp = ["DecayRule", "CavityRule", "KillHeadlessPlayerRule", "OneLivingPlayerRule"];
        if (config.maxSwaps > 0) combinedRuleConfig.swapAction = ["SwapPieceRule"];
        if (config.maxBites > 0) combinedRuleConfig.biteAction = ["BiteRule", "cleanUp"];

        return combinedRuleConfig;
    }

    inline static function makeBuildConfig(history:StateHistory, historyState:State):BuildConfig {
        return {
            history:history,
            historyState:historyState,
        };
    }

    inline static function makeBuildStateConfig(config:ScourgeConfig, buildCfg:BuildConfig) {
        return {
            buildCfg:buildCfg,
            firstPlayer:config.firstPlayer,
        };
    }

    inline static function makeBuildPlayersConfig(config:ScourgeConfig, buildCfg:BuildConfig) {
        return {
            buildCfg:buildCfg,
            numPlayers:config.numPlayers,
        };
    }

    inline static function makeBuildBoardConfig(config:ScourgeConfig, buildCfg:BuildConfig) {
        return {
            buildCfg:buildCfg,
            circular:config.circular,
            initGrid:config.initGrid,
        };
    }

    inline static function makeEatCellsConfig(config:ScourgeConfig) {
        return {
            recursive:config.eatRecursive,
            eatHeads:config.eatHeads,
            takeBodiesFromHeads:config.takeBodiesFromHeads,
            orthoOnly:config.orthoEatOnly,
        };
    }

    inline static function makeDecayConfig(config:ScourgeConfig) {
        return {
            orthoOnly:config.orthoDecayOnly,
        };
    }

    inline static function makePickPieceConfig(config:ScourgeConfig, buildCfg:BuildConfig, randomFunction:Void->Float) {
        return {
            buildCfg:buildCfg,
            pieceTableIDs:config.pieceTableIDs,
            allowFlipping:config.allowFlipping,
            allowRotating:config.allowRotating,
            allowAll:config.allowAllPieces,
            hatSize:config.pieceHatSize,
            randomFunction:randomFunction,
        };
    }

    inline static function makeDropPieceConfig(config:ScourgeConfig) {
        return {
            overlapSelf:config.overlapSelf,
            allowFlipping:config.allowFlipping,
            allowRotating:config.allowRotating,
            growGraph:config.growGraphWithDrop,
            allowNowhere:config.allowNowhereDrop,
            orthoOnly:config.orthoDropOnly,
            diagOnly:config.diagDropOnly,
        };
    }

    inline static function makeBiteConfig(config:ScourgeConfig) {
        return {
            minReach:config.minBiteReach,
            maxReach:config.maxBiteReach,
            maxSizeReference:config.maxSizeReference,
            baseReachOnThickness:config.baseBiteReachOnThickness,
            omnidirectional:config.omnidirectionalBite,
            biteThroughCavities:config.biteThroughCavities,
            biteHeads:config.biteHeads,
            orthoOnly:config.orthoBiteOnly,
            startingBites:config.startingBites,
        };
    }

    inline static function makeSwapConfig(config:ScourgeConfig) {
        return {
            startingSwaps:config.startingSwaps,
        };
    }

    inline static function makeSkipsExhaustedConfig(config:ScourgeConfig) {
        return {
            maxSkips:config.maxSkips,
        }
    }

    inline static function makeReplenishConfig(config:ScourgeConfig, buildCfg:BuildConfig) {
        var stateReplenishProperties:Array<ReplenishableConfig> = [];

        if (config.maxSwaps > 0) stateReplenishProperties.push({
            prop:SwapAspect.NUM_SWAPS,
            amount:config.swapBoost,
            period:config.swapPeriod,
            maxAmount:config.maxSwaps,
        });

        if (config.maxBites > 0) stateReplenishProperties.push({
            prop:BiteAspect.NUM_BITES,
            amount:config.biteBoost,
            period:config.bitePeriod,
            maxAmount:config.maxBites,
        });

        return {
            buildCfg:buildCfg,
            stateProperties:stateReplenishProperties,
            playerProperties:[],
            nodeProperties:[],
        };
    }
}
