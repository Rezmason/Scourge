package net.rezmason.scourge.controller;

import net.rezmason.ropes.Types.SavedState;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;

enum PlayerDef {
    Test(proxy:Game->(Void->Void)->Void);
    Human;
    Bot(difficulty:Int, period:Int);
    Remote;
}

typedef GameEvent = {
    var type:GameEventType;
    var timeIssued:Int;
    @:optional var timeReceived:Int;
    @:optional var player:Int;
}

typedef SavedGame = {
    var state:SavedState;
    var log:Array<GameEvent>;
    var config:ScourgeConfig;
    var timeSaved:Int;
}

enum GameEventType {
    PlayerAction(action:Int, move:Int);
    Ready;
    RefereeAction(action:RefereeActionType);
}

enum RefereeActionType {
    AllReady;
    Connect;
    Disconnect;
    Resume(savedState:String);
    Save;
    Init(config:String);
    RandomFloats(floats:String);
}
