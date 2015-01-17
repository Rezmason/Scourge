package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.aspects.PlyAspect;

typedef BuildStateConfig = { public var firstPlayer:Int; }

class BuildGlobalsRule extends RopesRule<BuildStateConfig> {

    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override private function _prime():Void {
        addGlobals();
        state.globals[currentPlayer_] = config.firstPlayer;
    }
}
