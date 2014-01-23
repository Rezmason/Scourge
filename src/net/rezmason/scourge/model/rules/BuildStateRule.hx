package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.Rule;
import net.rezmason.ropes.State;
import net.rezmason.scourge.model.aspects.PlyAspect;

using net.rezmason.utils.Pointers;

typedef BuildStateConfig = {
    public var buildCfg:BuildConfig;
    public var firstPlayer:Int;
}

class BuildStateRule extends Rule {

    private var cfg:BuildStateConfig;

    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    public function new(cfg:BuildStateConfig):Void {
        super();
        demiurgic = true;
        this.cfg = cfg;
    }

    override private function _prime():Void {
        plan.stateAspectTemplate.copyTo(state.aspects, 0);
        plan.stateAspectTemplate.mapTo(cfg.buildCfg.history.alloc, cfg.buildCfg.historyState.aspects, 0);
        state.aspects[currentPlayer_] = cfg.firstPlayer;
    }
}
