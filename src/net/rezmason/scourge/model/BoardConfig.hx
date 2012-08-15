package net.rezmason.scourge.model;

class BoardConfig {

    public var playerGenes(default, null):Array<String>;
    public var circular:Bool;
    public var rules(default, null):Array<Rule>;
    public var initGrid:String;

    public function new():Void {
        rules = [];
        playerGenes = [];
    }
}
