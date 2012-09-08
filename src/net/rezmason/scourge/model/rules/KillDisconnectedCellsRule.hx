package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;

using Lambda;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class KillDisconnectedCellsRule extends Rule {

    static var nodeReqs:AspectRequirements;
    static var playerReqs:AspectRequirements;
    static var option:Option = {optionID:0};

    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var freshness_:AspectPtr;
    var head_:AspectPtr;

    public function new():Void {
        super();

        if (nodeReqs == null)  nodeReqs = [
            OwnershipAspect.IS_FILLED,
            OwnershipAspect.OCCUPIER,
            FreshnessAspect.FRESHNESS,
        ];

        if (playerReqs == null) playerReqs = [
            BodyAspect.HEAD,
        ];
    }

    override public function init(state:State):Void {
        super.init(state);
        occupier_ = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        freshness_ = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        head_ =   state.playerAspectLookup[BodyAspect.HEAD.id];
    }

    //override public function listStateAspectRequirements():AspectRequirements { return reqs; }
    override public function listPlayerAspectRequirements():AspectRequirements { return playerReqs; }
    override public function listBoardAspectRequirements():AspectRequirements { return nodeReqs; }
    override public function getOptions():Array<Option> { return [option]; }

    override public function chooseOption(choice:Int):Void {
        // perform kill operation on state

        var nodesInPlay:Array<BoardNode> = [];

        var heads:Array<BoardNode> = [];
        for (ike in 0...state.players.length) {
            var head:Int = history.get(state.players[ike].at(head_));
            heads.push(state.nodes[head]);
        }

        var candidates:Array<BoardNode> = heads.expandGraph(true, isCandidate);
        var livingBodyNeighbors:Array<BoardNode> = heads.expandGraph(true, isLivingBodyNeighbor);

        for (candidate in candidates) if (!livingBodyNeighbors.has(candidate)) killCell(candidate.value);
    }

    function isCandidate(me:AspectSet, you:AspectSet):Bool {
        var occupier:Int = history.get(me.at(occupier_));
        var isFilled:Int = history.get(me.at(isFilled_));
        var freshness:Int = history.get(me.at(freshness_));
        if (isFilled > 0 && occupier > -1) return true;
        else if (freshness > 0) return true;
        return false;
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (history.get(me.at(isFilled_)) == 0) return false;
        return history.get(me.at(occupier_)) == history.get(you.at(occupier_));
    }

    function killCell(me:AspectSet):Void {
        history.set(me.at(isFilled_), 0);
        history.set(me.at(occupier_), -1);
    }

    /*
    function resetCell(me:AspectSet):Void {
        var template:AspectTemplate = state.nodeAspectTemplate;
        for (ike in 0...me.length) history.set(me[ike], template[ike]);
    }
    */
}

