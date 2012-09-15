package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

class Rule {

    var state:State;

    public var options(default, null):Array<Option>;
    public var stateAspectRequirements(default, null):AspectRequirements;
    public var playerAspectRequirements(default, null):AspectRequirements;
    public var nodeAspectRequirements(default, null):AspectRequirements;

    public function new():Void {
        stateAspectRequirements = [];
        playerAspectRequirements = [];
        nodeAspectRequirements = [];
        options = [];
    }

    public function init(state:State):Void { this.state = state; }
    public function update():Void {}

    public function chooseOption(choice:Int):Void {
        if (options == null || options.length < choice || options[choice] == null) {
            throw "Invalid choice index.";
        }
    }
}

