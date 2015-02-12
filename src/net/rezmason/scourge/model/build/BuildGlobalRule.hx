package net.rezmason.scourge.model.build;

import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.praxis.aspect.PlyAspect;

class BuildGlobalRule extends BaseRule<BuildGlobalParams> {

    @global(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    override private function _prime():Void {
        addGlobal();
        state.global[currentPlayer_] = params.firstPlayer;
    }
}
