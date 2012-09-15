package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

class State {

    public var aspects(default, null):AspectSet;
    public var players(default, null):Array<AspectSet>;
    public var nodes(default, null):Array<GridNode<AspectSet>>; // aka BoardNode

    public function new():Void {
        aspects = [];
        players = [];
        nodes = [];
    }
}
