package net.rezmason.scourge.model.bite;

typedef BiteParams = {
    minReach:Int,
    maxReach:Int,
    maxSizeReference:Int,
    baseReachOnThickness:Bool,
    omnidirectional:Bool,
    biteThroughCavities:Bool,
    biteHeads:Bool,
    orthoOnly:Bool,
    startingBites:Int,

    ?allowBiting:Bool,
}
