package net.rezmason.scourge.model.build;

import net.rezmason.ropes.RopesRule;
import net.rezmason.ropes.aspect.PlyAspect;

class BuildGlobalRule extends RopesRule<BuildGlobalParams> {

    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override private function _prime():Void {
        addGlobal();
        state.global[currentPlayer_] = params.firstPlayer;
    }
}
