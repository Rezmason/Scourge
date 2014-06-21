package net.rezmason.scourge.controller;

import net.rezmason.ropes.RopesTypes.SavedState;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.utils.Zig;

enum PlayerDef {
    Bot(smarts:Smarts, period:Int);
    Human;
    Remote;
}

typedef GameEvent = {
    var type:GameEventType;
    var timeIssued:Int;
    @:optional var timeReceived:Int;
}

typedef SavedGame = {
    var state:SavedState;
    var log:Array<GameEvent>;
    var floats:Array<Float>;
    var timeSaved:Int;
}

enum GameEventType {
    PlayerAction(type:PlayerActionType);
    RefereeAction(type:RefereeActionType);
}

enum PlayerActionType {
    SubmitMove(turn:Int, action:Int, move:Int);
}

enum RefereeActionType {
    Init(config:String, ?savedState:String);
    RelayMove(turn:Int, action:Int, move:Int);
    RandomFloats(turn:Int, floats:String);
    End;
}

enum NodeState {
    Wall;
    Empty;
    Cavity;
    Body;
    Head;
}

typedef NodeVO = {
    var id:Int;
    var occupier:Int;
    var state:Null<NodeState>;
    var freshness:Int;
};

