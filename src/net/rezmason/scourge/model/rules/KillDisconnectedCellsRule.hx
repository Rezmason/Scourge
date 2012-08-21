package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;

using Lambda;

using net.rezmason.scourge.model.GridUtils;

class KillDisconnectedCellsRule extends Rule {

    static var nodeReqs:AspectRequirements;
    static var option:Option = new Option();

    public function new():Void {
        super();

        if (nodeReqs == null)
        {
            nodeReqs = new AspectRequirements();
            nodeReqs.set(OwnershipAspect.id, OwnershipAspect);
            nodeReqs.set(FreshnessAspect.id, FreshnessAspect);
        }
    }

    //override public function listStateAspectRequirements():AspectRequirements { return reqs; }
    //override public function listPlayerAspectRequirements():AspectRequirements { return reqs; }
    override public function listBoardAspectRequirements():AspectRequirements { return nodeReqs; }

    override public function getOptions():Array<Option> { return [option]; }

    override public function chooseOption(choice:Option):Void {
        if (choice == option) {
            // perform kill operation on state

            var nodesInPlay:Array<BoardNode> = [];

            var heads:Array<BoardNode> = [];
            for (player in state.players) heads.push(state.nodes[player.head]);

            var candidates:Array<BoardNode> = heads.expandGraph(true, isCandidate);
            var livingBodyNeighbors:Array<BoardNode> = heads.expandGraph(true, isLivingBodyNeighbor);

            for (candidate in candidates) {
                if (!livingBodyNeighbors.has(candidate)) killCell(candidate.value);
            }
        }
    }

    function isCandidate(cell:Aspects, connection:Aspects):Bool {
        var owner:OwnershipAspect = cast cell.get(OwnershipAspect.id);
        var fresh:FreshnessAspect = cast cell.get(FreshnessAspect.id);

        if (hist[owner.isFilled] > 0 && hist[owner.occupier] > -1) {
            return true;
        } else if (hist[fresh.freshness] > 0) {
            return true;
        }

        return false;
    }

    function isLivingBodyNeighbor(cell:Aspects, connection:Aspects):Bool {
        var owner1:OwnershipAspect = cast cell.get(OwnershipAspect.id);
        var owner2:OwnershipAspect = cast connection.get(OwnershipAspect.id);
        return hist[owner1.isFilled] > 0 && hist[owner1.occupier] == hist[owner2.occupier];
    }

    function killCell(cell:Aspects):Void {
        var owner:OwnershipAspect = cast cell.get(OwnershipAspect.id);
        var fresh:FreshnessAspect = cast cell.get(FreshnessAspect.id);
        hist[fresh.freshness] = 0;
        hist[owner.isFilled] = 0;
        hist[owner.occupier] = -1;
    }
}

