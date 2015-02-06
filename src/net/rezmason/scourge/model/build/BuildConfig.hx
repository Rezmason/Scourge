package net.rezmason.scourge.model.build;

class BuildConfig extends Config<BuildParams> {

    var initGrid:String;

    public function new():Void {
        super();
        initGrid = null;
    }

    override public function id():String {
        return 'build';
    }

    public override function ruleComposition():RuleComposition {
        return null;
    }

    override public function defaultParams():Null<BuildParams> {
        return {
            firstPlayer:0,

            numPlayers:2,

            circular:false,
            initGrid:initGrid,
        };
    }
}
