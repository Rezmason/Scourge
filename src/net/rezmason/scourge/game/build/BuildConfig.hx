package net.rezmason.scourge.game.build;

import net.rezmason.scourge.game.ConfigTypes;

class BuildConfig extends ScourgeConfig<BuildParams> {

    var initGrid:String;

    public function new():Void {
        super();
        initGrid = null;
    }

    override function get_composition():Map<String, ScourgeRuleComposition<BuildParams>> {
        return [
            'buildGlobal'   => {def:BuildGlobalRule,    type:Builder, presenter:null},
            'buildPlayers'  => {def:BuildPlayersRule,   type:Builder, presenter:null},
            'buildBoard'    => {def:BuildBoardRule,     type:Builder, presenter:null},
        ];
    }

    override function get_defaultParams() {
        return {
            firstPlayer:0,
            numPlayers:4,
            cells:null,
        };
    }
}
