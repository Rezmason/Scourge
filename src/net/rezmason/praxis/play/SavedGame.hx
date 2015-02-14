package net.rezmason.praxis.play;

import net.rezmason.praxis.PraxisTypes.SavedState;

typedef SavedGame = {
    var state:SavedState;
    var log:Array<GameEvent>;
    var floatsLog:Array<Float>;
    var timeSaved:Int;
}
