package net.rezmason.scourge.model.build;

import net.rezmason.ropes.RopesRule;
import net.rezmason.scourge.model.meta.PlyAspect;

typedef BuildGlobalConfig = { public var firstPlayer:Int; }

class BuildGlobalRule extends RopesRule<BuildGlobalConfig> {

    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override private function _prime():Void {
        addGlobal();
        state.global[currentPlayer_] = params.firstPlayer;
    }
}
