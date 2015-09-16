package net.rezmason.scourge.game.build;

import net.rezmason.praxis.rule.Builder;
import net.rezmason.praxis.aspect.PlyAspect;

class GlobalBuilder extends Builder<GlobalBuildParams> {

    @global(PlyAspect.CURRENT_PLAYER, true) var currentPlayer_;

    override private function _prime():Void {
        addGlobal();
        state.global[currentPlayer_] = params.firstPlayer;
    }
}
