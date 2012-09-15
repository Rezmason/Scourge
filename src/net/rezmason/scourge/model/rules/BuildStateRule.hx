package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.rules.BuildRule;

using net.rezmason.utils.ArrayUtils;
using net.rezmason.utils.Pointers;

typedef BuildStateConfig = {>BuildConfig,
    public var firstPlayer:Int;
}

class BuildStateRule extends BuildRule {

    private var cfg:BuildStateConfig;

    var currentPlayer_:AspectPtr;

    public function new(cfg:BuildStateConfig):Void {
        super();
        this.cfg = cfg;

        stateAspectRequirements = [
            PlyAspect.CURRENT_PLAYER,
        ];
    }

    override public function init(state:State, plan:StatePlan):Void {
        super.init(state, plan);
        var aspects:AspectSet = buildAspectSet(plan.stateAspectTemplate);
        for (ike in 0...aspects.length) state.aspects[ike] = ike;

        var historyState:State = cfg.historyState;
        var aspects:AspectSet = buildHistAspectSet(plan.stateAspectTemplate, cfg.history);
        for (ike in 0...aspects.length) historyState.aspects[ike] = ike;

        currentPlayer_ = statePtr(PlyAspect.CURRENT_PLAYER);
        state.aspects.mod(currentPlayer_, cfg.firstPlayer);
    }
}
