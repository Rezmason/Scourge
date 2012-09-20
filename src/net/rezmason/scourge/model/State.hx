package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

class State {

    public var aspects(default, null):AspectSet;
    public var players(default, null):Array<AspectSet>;
    public var nodes(default, null):Array<GridNode<AspectSet>>; // aka BoardNode
    public var extras(default, null):Array<AspectSet>;

    public function new():Void {
        aspects = [];
        players = [];
        nodes = [];
        extras = [];
    }

    public function wipe():Void {
        aspects.splice(0, aspects.length);
        players.splice(0, players.length);
        nodes.splice(0, nodes.length);
        extras.splice(0, extras.length);
    }
}
