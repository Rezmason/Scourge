package net.rezmason.scourge.game.build;

import net.rezmason.praxis.config.Module;
import net.rezmason.praxis.config.RuleComposition;
import net.rezmason.praxis.config.RuleType;

class BuildModule extends Module<BuildParams> {

    var initGrid:String;

    public function new():Void {
        super();
        initGrid = null;
    }

    override public function composeRules():Map<String, RuleComposition<BuildParams>> {
        var rules:Map<String, RuleComposition<BuildParams>> = new Map();
        rules[ 'buildGlobal'] = {type:Builder(new GlobalBuilder()), isIncluded:null};
        rules['buildPlayers'] = {type:Builder(new PlayerBuilder()), isIncluded:null};
        rules[  'buildBoard'] = {type:Builder(new  BoardBuilder()), isIncluded:null};
        return rules;
    }

    override public function makeDefaultParams() {
        return {
            firstPlayer:0,
            numPlayers:4,
            cells:null,
        };
    }
}
