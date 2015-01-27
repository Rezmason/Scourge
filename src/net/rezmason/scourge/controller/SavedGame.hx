package net.rezmason.scourge.controller;

import net.rezmason.ropes.RopesTypes.SavedState;

typedef SavedGame = {
    var state:SavedState;
    var log:Array<GameEvent>;
    var floats:Array<Float>;
    var timeSaved:Int;
}
