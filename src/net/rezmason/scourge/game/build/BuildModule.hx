package net.rezmason.scourge.game.build;

import net.rezmason.praxis.config.Module;
import net.rezmason.praxis.config.RuleComposition;

class BuildModule extends Module<BuildParams> {

    var initGrid:String;

    public function new():Void {
        super();
        initGrid = null;
    }

    override public function composeRules():Map<String, RuleComposition<BuildParams>> {
        return [
            'buildGlobal'   => {type:Builder(new BuildGlobalRule())},
            'buildPlayers'  => {type:Builder(new BuildPlayersRule())},
            'buildBoard'    => {type:Builder(new BuildBoardRule())},
        ];
    }

    override public function makeDefaultParams() {
        return {
            firstPlayer:0,
            numPlayers:4,
            cells:null,
        };
    }
}
