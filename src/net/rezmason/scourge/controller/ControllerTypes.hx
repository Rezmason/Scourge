package net.rezmason.scourge.controller;

import net.rezmason.ropes.RopesTypes.SavedState;

typedef SavedGame = {
    var state:SavedState;
    var log:Array<GameEvent>;
    var floats:Array<Float>;
    var timeSaved:Int;
}

typedef GameEvent = {
    var type:GameEventType;
    var timeIssued:Int;
    @:optional var timeReceived:Int;
}

enum GameEventType {
    SubmitMove(turn:Int, action:Int, move:Int);
    Init(config:String, ?savedState:String);
    RelayMove(turn:Int, action:Int, move:Int);
    RandomFloats(turn:Int, floats:String);
    End;
}
