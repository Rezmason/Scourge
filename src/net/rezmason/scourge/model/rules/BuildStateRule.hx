package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.ModelTypes;
import net.rezmason.ropes.Rule;
import net.rezmason.ropes.State;
import net.rezmason.scourge.model.aspects.PlyAspect;

using net.rezmason.utils.ArrayUtils;
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

    override public function init():Void {

        var aspects:AspectSet = buildAspectSet(plan.stateAspectTemplate);
        for (ike in 0...aspects.length) state.aspects[ike] = aspects[ike];

        var historyState:State = cfg.buildCfg.historyState;
        var aspects:AspectSet = buildHistAspectSet(plan.stateAspectTemplate, cfg.buildCfg.history);
        for (ike in 0...aspects.length) historyState.aspects[ike] = aspects[ike];

        state.aspects.mod(currentPlayer_, cfg.firstPlayer);
    }
}
