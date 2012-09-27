package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.PlyAspect;

using net.rezmason.utils.ArrayUtils;
using net.rezmason.utils.Pointers;

typedef BuildStateConfig = {>BuildConfig,
    public var firstPlayer:Int;
}

class BuildStateRule extends Rule {

    private var cfg:BuildStateConfig;

    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_:AspectPtr;

    public function new(cfg:BuildStateConfig):Void {
        super();
        this.cfg = cfg;
    }

    override public function init(state:State, plan:StatePlan):Void {
        super.init(state, plan);

        var aspects:AspectSet = buildAspectSet(plan.stateAspectTemplate);
        for (ike in 0...aspects.length) state.aspects[ike] = aspects[ike];

        var historyState:State = cfg.historyState;
        var aspects:AspectSet = buildHistAspectSet(plan.stateAspectTemplate, cfg.history);
        for (ike in 0...aspects.length) historyState.aspects[ike] = aspects[ike];

        state.aspects.mod(currentPlayer_, cfg.firstPlayer);
    }
}
