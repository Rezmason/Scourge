package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.PlyAspect;

using net.rezmason.utils.ArrayUtils;
using net.rezmason.utils.Pointers;

typedef CreateStateConfig = {
    public var firstPlayer:Int;
    public var history:StateHistory;
}

class CreateStateRule extends Rule {

    private var cfg:CreateStateConfig;

    var currentPlayer_:AspectPtr;

    public function new(cfg:CreateStateConfig):Void {
        super();
        this.cfg = cfg;

        stateAspectRequirements = [
            PlyAspect.CURRENT_PLAYER,
        ];
    }

    override public function init(state:State, plan:StatePlan):Void {
        super.init(state, plan);
        var aspects:AspectSet = createAspectSet(plan.stateAspectTemplate, cfg.history);
        for (ike in 0...aspects.length) state.aspects[ike] = ike;

        currentPlayer_ = plan.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        state.aspects.mod(currentPlayer_, cfg.firstPlayer);
    }

    inline function createAspectSet(template:AspectSet, history:StateHistory):AspectSet {
        var aspects:AspectSet = new AspectSet();
        for (val in template) {
            //aspects.push(history.alloc(val)); // H
            aspects.push(val);
        }
        return aspects;
    }
}
