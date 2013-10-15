package net.rezmason.scourge.controller.players;

import net.rezmason.scourge.controller.Types;

class RemotePlayer implements Player {
    public var index(default, null):Int;
    public var ready(default, null):Bool;
    @:allow(net.rezmason.scourge.controller.Referee)
    private function send(event:GameEvent):Void {}
}
