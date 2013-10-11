package net.rezmason.scourge.model;

import net.rezmason.scourge.model.BuildConfig;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.Rule;
import net.rezmason.ropes.State;
import net.rezmason.utils.Siphon;
import net.rezmason.scourge.model.aspects.BiteAspect;
import net.rezmason.scourge.model.aspects.SwapAspect;
import net.rezmason.scourge.model.rules.*;
import net.rezmason.scourge.model.Pieces;
import net.rezmason.scourge.tools.Resource;
import net.rezmason.scourge.model.ScourgeAction.*;

typedef ReplenishableConfig = { prop:AspectProperty, amount:Int, period:Int, maxAmount:Int, }

class ScourgeConfigFactory {

    inline static var CLEAN_UP:String = 'cleanUp';
    inline static var WRAP_UP:String = 'wrapUp';

    static var BUILD_BOARD:String        = Siphon.getClassName(BuildBoardRule);
    static var BUILD_PLAYERS:String      = Siphon.getClassName(BuildPlayersRule);
    static var BUILD_STATE:String        = Siphon.getClassName(BuildStateRule);
    static var CAVITY:String             = Siphon.getClassName(CavityRule);
    static var DECAY:String              = Siphon.getClassName(DecayRule);
    static var DROP_PIECE:String         = Siphon.getClassName(DropPieceRule);
    static var EAT_CELLS:String          = Siphon.getClassName(EatCellsRule);
    static var END_TURN:String           = Siphon.getClassName(EndTurnRule);
    static var FORFEIT:String            = Siphon.getClassName(ForfeitRule);
    static var KILL_HEADLESS_BODY:String = Siphon.getClassName(KillHeadlessBodyRule);
    static var PICK_PIECE:String         = Siphon.getClassName(PickPieceRule);
    static var REPLENISH:String          = Siphon.getClassName(ReplenishRule);
    static var SKIPS_EXHAUSTED:String    = Siphon.getClassName(SkipsExhaustedRule);
    static var ONE_LIVING_PLAYER:String  = Siphon.getClassName(OneLivingPlayerRule);
    static var BITE:String               = Siphon.getClassName(BiteRule);
    static var SWAP_PIECE:String         = Siphon.getClassName(SwapPieceRule);

    // static var SPIT_BOARD:String = Siphon.getClassName(SpitBoardRule);

    public static var ruleDefs:Map<String, Class<Rule>> = cast Siphon.getDefs('net.rezmason.scourge.model.rules', 'src', 'Rule');

    public inline static function makeDefaultActionList():Array<String> return [DROP_ACTION, QUIT_ACTION];
    public inline static function makeStartAction():String return START_ACTION;
    public static function makeDemiurgicRuleList():Array<String> return [BUILD_STATE, BUILD_PLAYERS, BUILD_BOARD];
    public static function makeActionList(config:ScourgeConfig):Array<String> {

        var actionList:Array<String> = [QUIT_ACTION, DROP_ACTION/*, PICK_ACTION*/];

        if (config.maxSwaps > 0) actionList.push(SWAP_ACTION);
        if (config.maxBites > 0) actionList.push(BITE_ACTION);

        return actionList;
    }

    public static function makeDefaultConfig():ScourgeConfig {

        var pieces:Pieces = new Pieces(Resource.getString('tables/pieces.json.txt'));

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
            pieces:pieces,
            pieceTableIDs:pieces.getAllPieceIDsOfSize(4),
        };
    }

    public static function makeRuleConfig(config:ScourgeConfig, randomFunction:Void->Float, history:StateHistory, historyState:State):Map<String, Dynamic> {
        var buildCfg:BuildConfig = makeBuildConfig(history, historyState);

        var ruleConfig:Map<String, Dynamic> = [
            BUILD_STATE => makeBuildStateConfig(config, buildCfg),
            BUILD_PLAYERS => makeBuildPlayersConfig(config, buildCfg),
            BUILD_BOARD => makeBuildBoardConfig(config, buildCfg),
            EAT_CELLS => makeEatCellsConfig(config),
            DECAY => makeDecayConfig(config),
            DROP_PIECE => makeDropPieceConfig(config),
            REPLENISH => makeReplenishConfig(config, buildCfg),
            SKIPS_EXHAUSTED => makeSkipsExhaustedConfig(config),

            END_TURN => null,
            FORFEIT => null,
            KILL_HEADLESS_BODY => null,
            ONE_LIVING_PLAYER => null,

            //SPIT_BOARD => null,
        ];

        if (!config.allowAllPieces) ruleConfig.set(PICK_PIECE, makePickPieceConfig(config, buildCfg, randomFunction));
        if (config.includeCavities) ruleConfig.set(CAVITY, null);
        if (!config.allowAllPieces && config.maxSwaps > 0) ruleConfig.set(SWAP_PIECE, makeSwapConfig(config));
        if (config.maxBites > 0) ruleConfig.set(BITE, makeBiteConfig(config));

        return ruleConfig;
    }

    public static function makeCombinedRuleCfg(config:ScourgeConfig):Map<String, Array<String>> {

        var combinedRuleConfig:Map<String, Array<String>> = [
            CLEAN_UP => [DECAY, KILL_HEADLESS_BODY, ONE_LIVING_PLAYER],
            WRAP_UP  => [END_TURN, REPLENISH],

            START_ACTION => [CLEAN_UP],
            QUIT_ACTION  => [FORFEIT, CLEAN_UP, WRAP_UP],
            DROP_ACTION  => [DROP_PIECE, EAT_CELLS, CLEAN_UP, WRAP_UP, SKIPS_EXHAUSTED],
        ];

        if (config.includeCavities) combinedRuleConfig[CLEAN_UP].insert(1, CAVITY);
        if (!config.allowAllPieces && config.maxSwaps > 0) combinedRuleConfig[SWAP_ACTION] = [SWAP_PIECE, PICK_PIECE];
        if (config.maxBites > 0) combinedRuleConfig[BITE_ACTION] = [BITE, CLEAN_UP];

        if (!config.allowAllPieces) {
            combinedRuleConfig[START_ACTION].push(PICK_PIECE);
            combinedRuleConfig[WRAP_UP].push(PICK_PIECE);
        }

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
            hatSize:config.pieceHatSize,
            randomFunction:randomFunction,
            pieces:config.pieces,
        };
    }

    inline static function makeDropPieceConfig(config:ScourgeConfig) {
        return {
            overlapSelf:config.overlapSelf,
            pieceTableIDs:config.pieceTableIDs,
            allowFlipping:config.allowFlipping,
            allowRotating:config.allowRotating,
            growGraph:config.growGraphWithDrop,
            allowNowhere:config.allowNowhereDrop,
            allowPiecePick:config.allowAllPieces,
            orthoOnly:config.orthoDropOnly,
            diagOnly:config.diagDropOnly,
            pieces:config.pieces,
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
