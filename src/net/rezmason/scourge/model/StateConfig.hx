package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

class StateConfig {

    public var playerGenes(default, null):Array<String>;
    public var playerHeads(default, null):Array<BoardNode>;
    public var rules(default, null):Array<Rule>;

    public function new():Void {
        rules = [];
        playerGenes = [];
        playerHeads = [];
    }
}
