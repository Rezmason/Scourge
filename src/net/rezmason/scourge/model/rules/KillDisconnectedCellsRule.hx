package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;

using Lambda;

using net.rezmason.scourge.model.GridUtils;

class KillDisconnectedCellsRule extends Rule {

    static var nodeReqs:AspectRequirements;
    static var playerReqs:AspectRequirements;
    static var option:Option = new Option();

    var occupier_:Int;
    var isFilled_:Int;
    var freshness_:Int;
    var head_:Int;

    public function new():Void {
        super();

        if (nodeReqs == null)  nodeReqs = [
            OwnershipAspect.IS_FILLED,
            OwnershipAspect.OCCUPIER,
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

    override public function chooseOption(choice:Option):Void {
        if (choice == option) {

            // perform kill operation on state

            var nodesInPlay:Array<BoardNode> = [];

            var heads:Array<BoardNode> = [];
            for (player in state.players) heads.push(state.nodes[history.get(player[head_])]);

            var candidates:Array<BoardNode> = heads.expandGraph(true, isCandidate);
            var livingBodyNeighbors:Array<BoardNode> = heads.expandGraph(true, isLivingBodyNeighbor);

            for (candidate in candidates) {
                if (!livingBodyNeighbors.has(candidate)) killCell(candidate.value);
            }
        }
    }

    function isCandidate(me:Aspects, you:Aspects):Bool {
        var occupier:Int = history.get(me[occupier_]);
        var freshness:Int = history.get(me[freshness_]);
        if (occupier > 0 && occupier > -1) return true;
        else if (freshness > 0) return true;
        return false;
    }

    function isLivingBodyNeighbor(me:Aspects, you:Aspects):Bool {
        if (history.get(me[isFilled_]) > 0) return true;
        return history.get(me[occupier_]) == history.get(you[occupier_]);
    }

    function killCell(me:Aspects):Void {
        history.set(me[occupier_], -1);
        history.set(me[isFilled_], 0);
        history.set(me[freshness_], 0);
    }
}

