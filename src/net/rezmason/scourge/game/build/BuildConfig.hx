package net.rezmason.scourge.game.build;

import net.rezmason.praxis.config.Config;
import net.rezmason.praxis.config.RuleComposition;

class BuildConfig extends Config<BuildParams> {

    var initGrid:String;

    public function new():Void {
        super();
        initGrid = null;
    }

    override function get_composition():Map<String, RuleComposition<BuildParams>> {
        return [
            'buildGlobal'   => {type:Builder(new BuildGlobalRule())},
            'buildPlayers'  => {type:Builder(new BuildPlayersRule())},
            'buildBoard'    => {type:Builder(new BuildBoardRule())},
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
