package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.PieceTypes;
import net.rezmason.scourge.model.aspects.PieceAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

import Std.int;

using net.rezmason.ropes.AspectUtils;
using net.rezmason.utils.Pointers;

typedef PickPieceConfig = {
    public var buildCfg:BuildConfig;
    public var pieceTableIDs:Array<Int>; // The list of pieces available at any point in the game
    public var allowFlipping:Bool; // If false, the reflection is left to chance
    public var allowRotating:Bool; // If false, the rotation is left to chance
    public var allowAll:Bool; // if true, nothing is left to chance
    public var hatSize:Int; // Number of pieces in the "hat" before it's refilled
    public var randomFunction:Void->Float; // Source of random numbers
}

typedef PickPieceOption = {>Option,
    var hatIndex:Int;
    var pieceTableID:Int;
    var rotation:Int;
    var reflection:Int;
}

class PickPieceRule extends Rule {

    static var stateReqs:AspectRequirements;

    private var cfg:PickPieceConfig;

    private var allOptions:Array<PickPieceOption>;
    private var pickOption:Option;

    // This rule is surprisingly complex

    @extra(PieceAspect.PIECE_HAT_NEXT) var pieceHatNext_;
    @extra(PieceAspect.PIECE_HAT_PREV) var pieceHatPrev_;

    @extra(PieceAspect.PIECE_ID) var pieceID_;
    @extra(PieceAspect.PIECE_NEXT) var pieceNext_;
    @extra(PieceAspect.PIECE_PREV) var piecePrev_;

    @extra(PieceAspect.PIECE_OPTION_ID) var pieceOptionID_;

    @state(PieceAspect.PIECES_PICKED) var piecesPicked_;
    @state(PieceAspect.PIECE_FIRST) var pieceFirst_;
    @state(PieceAspect.PIECE_HAT_FIRST) var pieceHatFirst_;
    @state(PieceAspect.PIECE_REFLECTION) var pieceReflection_;
    @state(PieceAspect.PIECE_ROTATION) var pieceRotation_;
    @state(PieceAspect.PIECE_TABLE_ID) var pieceTableID_;

    @state(PieceAspect.PIECE_HAT_PLAYER) var pieceHatPlayer_;
    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    public function new(cfg:PickPieceConfig):Void {
        super();
        this.cfg = cfg;
        if (cfg.hatSize > cfg.pieceTableIDs.length) cfg.hatSize = cfg.pieceTableIDs.length;
    }

    // All this for an overglorified random piece picker!

    override private function _prime():Void {
        buildPieceOptions();
        buildHat();
    }

    override private function _update():Void {

        if (cfg.allowAll) {
            // The simplest system; the player can use any provided piece at any time
            options = cast allOptions.copy();
            quantumOptions = [];
        } else if (remakeHat()) {
            // The hat's been refilled; all piece options are available as quantum options
            options = [pickOption];
            quantumOptions = cast allOptions.copy();
        } else if (state.aspects.at(pieceTableID_) == Aspect.NULL) {
            options = [pickOption];

            // Iterate over the hat's contents and incrlude the corresopnding quantum options

            var quantumPieceOptions:Array<PickPieceOption> = [];
            var firstHatPiece:AspectSet = getExtra(state.aspects.at(pieceHatFirst_));
            var hatPieces:Array<AspectSet> = firstHatPiece.listToArray(state.extras, pieceHatNext_);
            for (piece in hatPieces) quantumPieceOptions.push(allOptions[piece.at(pieceOptionID_)]);
            quantumOptions = cast quantumPieceOptions;
        }
    }

    override private function _chooseOption(choice:Int):Void {

        var option:PickPieceOption = cast options[choice];
        if (cfg.allowAll) {
            // The player's choice is selected
            setPiece(option.pieceTableID, option.reflection, option.rotation);
        } else {
            // A selection is made randomly
            if (remakeHat()) buildHat();
            option = pickOptionFromHat();
            setPiece(option.pieceTableID, option.reflection, option.rotation);
        }
    }

    override private function _chooseQuantumOption(choice:Int):Void {
                // The player's choice is selected
        var option:PickPieceOption = cast options[choice];
        if (remakeHat()) buildHat();
        pickOptionFromHat(option);
        setPiece(option.pieceTableID, option.reflection, option.rotation);
    }

    private function buildPieceOptions():Void {

        // Every option has to be made before the game begins. These options
        // are reused throughout the game to represent the hat's contents.

        allOptions = [];
        pickOption = {optionID:0};

        // We create the table of piece frequencies from the config

        var pieceFrequencies:Array<Null<Int>> = [];
        for (pieceTableID in cfg.pieceTableIDs) {
            if (pieceFrequencies[pieceTableID] == null) pieceFrequencies[pieceTableID] = 0;
            pieceFrequencies[pieceTableID]++;
        }

        // Create an option for every element being picked randomly

        for (pieceTableID in 0...pieceFrequencies.length) {
            var freq:Null<Int> = pieceFrequencies[pieceTableID];
            if (freq == 0 || freq == null) continue;

            var piece:PieceGroup = Pieces.getPieceById(pieceTableID);

            // A piece that can't be flipped or rotated has its multiple symmetries
            // added to the hat, and so it has more options

            if (cfg.allowFlipping) {
                if (cfg.allowRotating) {
                    makeOption(pieceTableID, 0, 0, freq);
                } else {
                    var spinWeight:Int = int(piece[0].length / 4);
                    for (rotation in 0...piece[0].length) makeOption(pieceTableID, 0, rotation, freq * spinWeight);
                }
            } else {
                for (flip in 0...piece.length) {
                    if (cfg.allowRotating) {
                        makeOption(pieceTableID, flip, 0, freq);
                    } else {
                        var spinWeight:Int = int(piece[flip].length / 4);
                        for (rotation in 0...piece[flip].length) makeOption(pieceTableID, flip, rotation, freq * spinWeight);
                    }
                }
            }
        }

        // Create a hat extra for every option
        var allPieces:Array<AspectSet> = [];
        for (option in allOptions) {
            extraAspectTemplate.mod(pieceID_, numExtras());
            option.hatIndex = numExtras();
            var piece:AspectSet = buildExtra();
            piece.mod(pieceOptionID_, option.optionID);
            allPieces.push(piece);
            state.extras.push(piece);
            cfg.buildCfg.historyState.extras.push(buildHistExtra(cfg.buildCfg.history));
        }

        allPieces.chainByAspect(pieceID_, pieceNext_, piecePrev_);
        state.aspects.mod(pieceFirst_, allPieces[0].at(pieceID_));
    }

    private function makeOption(pieceTableID:Int, reflection:Int, rotation:Int, weight:Int):PickPieceOption {
        var option:PickPieceOption = {
            pieceTableID:pieceTableID,
            rotation:rotation,
            reflection:reflection,
            weight:weight,
            relatedOptionID:0,
            optionID:allOptions.length,
            hatIndex:0,
        };
        allOptions.push(option);
        return option;
    }

    private function setPiece(pieceTableID:Int, reflection:Int, rotation:Int):Void {
        state.aspects.mod(pieceTableID_, pieceTableID);
        state.aspects.mod(pieceReflection_, reflection);
        state.aspects.mod(pieceRotation_, rotation);
    }

    private function pickOptionFromHat(option:PickPieceOption = null):PickPieceOption {

        var firstHatPiece:AspectSet = getExtra(state.aspects.at(pieceHatFirst_));
        var hatPieces:Array<AspectSet> = firstHatPiece.listToArray(state.extras, pieceHatNext_);

        // Because pieces are differently weighted, we need to use a binary search algo
        // to retrieve a picked piece

        // ...or maybe not. TODO: Revisit this

        var maxWeight:Float = 0;
        var weights:Array<Float> = [];
        for (piece in hatPieces) {
            weights.push(maxWeight);
            maxWeight += allOptions[piece.at(pieceOptionID_)].weight;
        }

        var pickedPiece:AspectSet = null;
        if (option == null) {
            var pick:Float = cfg.randomFunction() * maxWeight;
            pickedPiece = hatPieces[binarySearch(pick, weights)];
            option = allOptions[pickedPiece.at(pieceOptionID_)];
        } else {
            pickedPiece = getExtra(option.hatIndex);
        }


        state.aspects.mod(piecesPicked_, state.aspects.at(piecesPicked_) + 1);

        var nextPiece:AspectSet = pickedPiece.removeSet(state.extras, pieceHatNext_, pieceHatPrev_);

        if (pickedPiece == firstHatPiece) {
            firstHatPiece = nextPiece;
            if (firstHatPiece == null) state.aspects.mod(pieceHatFirst_, Aspect.NULL);
            else state.aspects.mod(pieceHatFirst_, firstHatPiece.at(pieceID_));
        }

        return option;
    }

    private function buildHat():Void {
        var firstPiece:AspectSet = getExtra(state.aspects.at(pieceFirst_));
        var allPieces:Array<AspectSet> = firstPiece.listToArray(state.extras, pieceNext_);
        allPieces.chainByAspect(pieceID_, pieceHatNext_, pieceHatPrev_);
        state.aspects.mod(pieceHatFirst_, firstPiece.at(pieceID_));
        state.aspects.mod(piecesPicked_, 0);
        state.aspects.mod(pieceHatPlayer_, state.aspects.at(currentPlayer_));
    }

    private function binarySearch(val:Float, list:Array<Float>):Int {
        function search(min:Int, max:Int):Int {
            var halfway:Int = int((min + max) * 0.5);
            if (max < min) return -1;
            else if (list[halfway] > val) return search(min, halfway - 1);
            else if (list[halfway] < val) return search(halfway + 1, max);
            else return halfway;
        }

        return search(0, list.length);
    }

    // We fill the hat up again if it's empty
    private function remakeHat():Bool {
        return state.aspects.at(pieceHatPlayer_) != state.aspects.at(currentPlayer_) ||
                state.aspects.at(piecesPicked_) == cfg.hatSize;
    }
}
