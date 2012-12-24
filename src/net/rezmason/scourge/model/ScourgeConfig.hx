package net.rezmason.scourge.model;

typedef ScourgeConfig = {
    var allowAllPieces:Bool;
    var allowFlipping:Bool;
    var allowNowhereDrop:Bool;
    var allowRotating:Bool;
    var baseBiteReachOnThickness:Bool;
    var biteHeads:Bool;
    var biteThroughCavities:Bool;
    var circular:Bool;
    var diagDropOnly:Bool;
    var eatHeads:Bool;
    var eatRecursive:Bool;
    var growGraphWithDrop:Bool;
    var includeCavities:Bool;
    var omnidirectionalBite:Bool;
    var orthoBiteOnly:Bool;
    var orthoDecayOnly:Bool;
    var orthoDropOnly:Bool;
    var orthoEatOnly:Bool;
    var overlapSelf:Bool;
    var takeBodiesFromHeads:Bool;
    var firstPlayer:Int;
    var maxBiteReach:Int;
    var maxSizeReference:Int;
    var maxSkips:Int;
    var minBiteReach:Int;
    var numPlayers:Int;
    var pieceHatSize:Int;
    var startingSwaps:Int;
    var startingBites:Int;
    var swapBoost:Int;
    var swapPeriod:Int;
    var maxSwaps:Int;
    var biteBoost:Int;
    var bitePeriod:Int;
    var maxBites:Int;
    var initGrid:String;
    var pieceTableIDs:Array<Int>;
    var randomFunction:Void->Float;
}
