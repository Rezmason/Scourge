package net.rezmason.scourge.model.build;

class BuildConfig<RP, MP> extends Config<BuildParams, RP, MP> {

    var initGrid:String;

    public function new():Void {
        super();
        initGrid = null;
    }

    override public function composition():Map<String, RuleComposition<BuildParams, RP, MP>> {
        return [
            'buildGlobal'   => {def:BuildGlobalRule,    type:Builder, presenter:null},
            'buildPlayers'  => {def:BuildPlayersRule,   type:Builder, presenter:null},
            'buildBoard'    => {def:BuildBoardRule,     type:Builder, presenter:null},
        ];
    }

    override public function defaultParams():Null<BuildParams> {
        return {
            firstPlayer:0,

            numPlayers:4,

            circular:false,
            initGrid:initGrid,
        };
    }
}
