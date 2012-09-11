package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class ForfeitRule extends Rule {

    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var freshness_:AspectPtr;
    var head_:AspectPtr;
    var currentPlayer_:AspectPtr;
    var bodyFirst_:AspectPtr;
    var bodyNext_:AspectPtr;

    public function new():Void {
        super();

        stateAspectRequirements = [
            PlyAspect.CURRENT_PLAYER,
        ];

        playerAspectRequirements = [
            BodyAspect.HEAD,
        ];

        nodeAspectRequirements = [
            OwnershipAspect.IS_FILLED,
            OwnershipAspect.OCCUPIER,
            FreshnessAspect.FRESHNESS,
        ];

        options.push({optionID:0});
    }

    override public function init(state:State):Void {
        super.init(state);
        occupier_ = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        freshness_ = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        head_ =   state.playerAspectLookup[BodyAspect.HEAD.id];
        currentPlayer_ = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];

        bodyFirst_ = state.nodeAspectLookup[BodyAspect.BODY_FIRST.id];
        bodyNext_ = state.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));
        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];
        for (node in playerHead.getGraph(true, isLivingBodyNeighbor)) killCell(node.value);
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (history.get(me.at(isFilled_)) == 0) return false;
        return history.get(me.at(occupier_)) == history.get(you.at(occupier_));
    }

    function killCell(me:AspectSet):Void {
        history.set(me.at(isFilled_), 0);
        history.set(me.at(occupier_), -1);
    }
}

