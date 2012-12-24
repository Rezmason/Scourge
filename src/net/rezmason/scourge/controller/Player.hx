package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.Types;

class Player {

    public var ready(default, null):Bool;

    public function new(config:PlayerConfig):Void {}

    public function send(event:GameEvent):Void {}
}
