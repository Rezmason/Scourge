package net.rezmason.scourge.controller;

import net.rezmason.ropes.Types.SavedState;
import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.utils.Zig;

enum PlayerDef {
    Test(proxy:Game->(Void->Void)->Void);
    Human;
    Bot(smarts:Smarts, period:Int);
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
    var floats:Array<Float>;
    var timeSaved:Int;
}

typedef PlaySignal = Zig<Player->GameEvent->Void>;

enum GameEventType {
    PlayerAction(action:PlayerActionType);
    RefereeAction(action:RefereeActionType);
}

enum PlayerActionType {
    SubmitMove(action:Int, move:Int);
    Ready;
    Synced;
}

enum RefereeActionType {
    AllReady;
    AllSynced;
    Connect;
    Disconnect;
    Save;
    Init(config:String, ?savedState:String);
    RandomFloats(floats:String);
}
