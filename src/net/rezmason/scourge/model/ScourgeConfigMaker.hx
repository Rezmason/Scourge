package net.rezmason.scourge.model;

import net.rezmason.scourge.model.BuildConfig;
import net.rezmason.ropes.ModelTypes;
import net.rezmason.ropes.Rule;
import net.rezmason.ropes.State;
import net.rezmason.utils.Siphon;
import net.rezmason.scourge.model.aspects.BiteAspect;
import net.rezmason.scourge.model.aspects.SwapAspect;
import net.rezmason.scourge.model.Pieces;

typedef ReplenishableConfig = { prop:AspectProperty, amount:Int, period:Int, maxAmount:Int, }

class ScourgeConfigMaker {

    public var allowAllPieces:Bool;
    public var allowFlipping:Bool;
    public var allowNowhereDrop:Bool;
    public var allowRotating:Bool;
    public var baseBiteReachOnThickness:Bool;
    public var biteHeads:Bool;
    public var biteThroughCavities:Bool;
    public var circular:Bool;
    public var diagDropOnly:Bool;
    public var eatHeads:Bool;
    public var eatRecursive:Bool;
    public var growGraphWithDrop:Bool;
    public var omnidirectionalBite:Bool;
    public var orthoBiteOnly:Bool;
    public var orthoDecayOnly:Bool;
    public var orthoDropOnly:Bool;
    public var orthoEatOnly:Bool;
    public var overlapSelf:Bool;
    public var takeBodiesFromHeads:Bool;
    public var firstPlayer:Int;
    public var maxBiteReach:Int;
    public var maxSizeReference:Int;
    public var maxSkips:Int;
    public var minBiteReach:Int;
    public var numPlayers:Int;
    public var pieceHatSize:Int;
    public var startingSwaps:Int;
    public var startingBites:Int;
    public var swapBoost:Int;
    public var swapPeriod:Int;
    public var maxSwaps:Int;
    public var biteBoost:Int;
    public var bitePeriod:Int;
    public var maxBites:Int;
    public var initGrid:String;
    public var pieceTableIDs:Array<Int>;
    public var randomFunction:Void->Float;

    public static var ruleDefs:Hash<Class<Rule>> = cast Siphon.getDefs("net.rezmason.scourge.model.rules", "src", "Rule");

    public static var combinedRuleCfg(default, null):Dynamic<Array<String>> = {
        cleanUp: ["DecayRule", "CavityRule", "KillHeadlessPlayerRule", "OneLivingPlayerRule"],
        wrapUp: ["EndTurnRule", "ReplenishRule", "PickPieceRule"],

        startAction: ["cleanUp", "PickPieceRule"],
        biteAction: ["BiteRule", "cleanUp"],
        swapAction: ["SwapPieceRule", "PickPieceRule"],
        quitAction: ["ForfeitRule", "cleanUp", "wrapUp"],
        dropAction: ["DropPieceRule", "EatCellsRule", "cleanUp", "wrapUp", "SkipsExhaustedRule"],
    }

    public static var defaultAction(default, null):String = "dropAction";

    public static var actionList(default, null):Array<String> = ["biteAction", "swapAction", "quitAction", "dropAction",];
    public static var startAction:String = "startAction";

    public function new():Void {
        reset();
    }

    public function reset():Void {
        allowAllPieces = false;
        allowFlipping = false;
        allowNowhereDrop = true;
        allowRotating = true;
        baseBiteReachOnThickness = false;
        biteHeads = true;
        biteThroughCavities = false;
        circular = false;
        diagDropOnly = false;
        eatHeads = true;
        eatRecursive = true;
        growGraphWithDrop = false;
        omnidirectionalBite = false;
        orthoBiteOnly = true;
        orthoDecayOnly = true;
        orthoDropOnly = true;
        orthoEatOnly = false;
        overlapSelf = false;
        takeBodiesFromHeads = true;
        firstPlayer = 0;
        maxBiteReach = 3;
        maxSizeReference = Std.int(400 * 0.7);
        minBiteReach = 1;
        numPlayers = 4;
        pieceHatSize = 5;
        startingSwaps = 5;
        startingBites = 5;
        swapBoost = 1;
        swapPeriod = 4;
        maxSwaps = 10;
        biteBoost = 1;
        bitePeriod = 3;
        maxBites = 10;
        maxSkips = 3;
        initGrid = null;
        pieceTableIDs = Pieces.getAllPieceIDsOfSize(4);
        randomFunction = function() return 0;
    }

    public function makeConfig(history:StateHistory, historyState:State):Dynamic {
        var buildCfg:BuildConfig = makeBuildConfig(history, historyState);

        return {
            BuildStateRule: makeBuildStateConfig(buildCfg),
            BuildPlayersRule: makeBuildPlayersConfig(buildCfg),
            BuildBoardRule: makeBuildBoardConfig(buildCfg),
            EatCellsRule: makeEatCellsConfig(),
            DecayRule: makeDecayConfig(),
            PickPieceRule: makePickPieceConfig(buildCfg),
            DropPieceRule: makeDropPieceConfig(),
            BiteRule: makeBiteConfig(),
            SwapPieceRule: makeSwapConfig(),
            ReplenishRule: makeReplenishConfig(buildCfg),
            SkipsExhaustedRule: makeSkipsExhaustedConfig(),

            CavityRule: null,
            EndTurnRule: null,
            ForfeitRule: null,
            KillHeadlessPlayerRule: null,
            OneLivingPlayerRule: null,
        };
    }

    function makeBuildConfig(history:StateHistory, historyState:State):BuildConfig {
        return {
            history:history,
            historyState:historyState,
        };
    }

    function makeBuildStateConfig(buildCfg) {
        return {
            buildCfg:buildCfg,
            firstPlayer:firstPlayer,
        };
    }

    function makeBuildPlayersConfig(buildCfg) {
        return {
            buildCfg:buildCfg,
            numPlayers:numPlayers,
        };
    }

    function makeBuildBoardConfig(buildCfg) {
        return {
            buildCfg:buildCfg,
            circular:circular,
            initGrid:initGrid,
        };
    }

    function makeEatCellsConfig() {
        return {
            recursive:eatRecursive,
            eatHeads:eatHeads,
            takeBodiesFromHeads:takeBodiesFromHeads,
            orthoOnly:orthoEatOnly,
        };
    }

    function makeDecayConfig() {
        return {
            orthoOnly:orthoDecayOnly,
        };
    }

    function makePickPieceConfig(buildCfg) {
        return {
            buildCfg:buildCfg,
            pieceTableIDs:pieceTableIDs,
            allowFlipping:allowFlipping,
            allowRotating:allowRotating,
            allowAll:allowAllPieces,
            hatSize:pieceHatSize,
            randomFunction:randomFunction,
        };
    }

    function makeDropPieceConfig() {
        return {
            overlapSelf:overlapSelf,
            allowFlipping:allowFlipping,
            allowRotating:allowRotating,
            growGraph:growGraphWithDrop,
            allowNowhere:allowNowhereDrop,
            orthoOnly:orthoDropOnly,
            diagOnly:diagDropOnly,
        };
    }

    function makeBiteConfig() {
        return {
            minReach:minBiteReach,
            maxReach:maxBiteReach,
            maxSizeReference:maxSizeReference,
            baseReachOnThickness:baseBiteReachOnThickness,
            omnidirectional:omnidirectionalBite,
            biteThroughCavities:biteThroughCavities,
            biteHeads:biteHeads,
            orthoOnly:orthoBiteOnly,
            startingBites:startingBites,
        };
    }

    function makeSwapConfig() {
        return {
            startingSwaps:startingSwaps,
        };
    }

    function makeSkipsExhaustedConfig() {
        return {
            maxSkips:maxSkips,
        }
    }

    function makeReplenishConfig(buildCfg) {
        var stateReplenishProperties:Array<ReplenishableConfig> = [];

        if (maxSwaps > 0) stateReplenishProperties.push({prop:SwapAspect.NUM_SWAPS, amount:swapBoost, period:swapPeriod, maxAmount:maxSwaps,});
        if (maxBites > 0) stateReplenishProperties.push({prop:BiteAspect.NUM_BITES, amount:biteBoost, period:bitePeriod, maxAmount:maxBites,});

        return {
            buildCfg:buildCfg,
            stateProperties:stateReplenishProperties,
            playerProperties:[],
            nodeProperties:[],
        };
    }
}
