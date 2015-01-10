package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.ControllerTypes.GameEvent;
import net.rezmason.scourge.model.Game;
import net.rezmason.utils.Zig;

interface IPlayerMediator {
    
    public function connect(game:Game):Void;
    public function disconnect():Void;

    public function moveStarts(playerIndex:Int, action:Int, move:Int):Void;
    public function moveStops():Void;
    public function moveSteps(cause:String):Void;

    public var proceedSignal(default, null):Zig<Void->Void>;
}
