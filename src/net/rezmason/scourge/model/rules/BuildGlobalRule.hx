package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.aspects.PlyAspect;

typedef BuildGlobalConfig = { public var firstPlayer:Int; }

class BuildGlobalRule extends RopesRule<BuildGlobalConfig> {

    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override private function _prime():Void {
        addGlobal();
        state.global[currentPlayer_] = params.firstPlayer;
    }
}
