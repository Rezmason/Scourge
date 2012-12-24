package net.rezmason.scourge.controller;

import net.rezmason.ropes.Types.SavedState;
import net.rezmason.scourge.model.ScourgeConfig;

typedef PlayerConfig = {
    var type:PlayerType;
}

enum PlayerType {
    Test;
    Human;
    Machine;
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
    Chat(message:String);
    Error;
    PlayerAction(action:Int, option:Int);
    Ready;
    RefereeAction(action:RefereeActionType);
}

enum RefereeActionType {
    AllReady;
    Connect(handler:Player->GameEvent->Void);
    Disconnect;
    Resume(savedState:String);
    Save;
    Init(config:String);
}
