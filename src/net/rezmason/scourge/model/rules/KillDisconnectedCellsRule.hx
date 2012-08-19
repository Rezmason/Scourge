package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

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
            for (player in state.players) heads.push(player.head);

            var candidates:Array<BoardNode> = heads.expandGraph(true, isCandidate);
            var livingBodyNeighbors:Array<BoardNode> = heads.expandGraph(true, isLivingBodyNeighbor);

            for (candidate in candidates) {
                if (!livingBodyNeighbors.has(candidate)) killCell(candidate.value);
            }
        }
    }

    function isCandidate(cell:Aspects, connection:Aspects):Bool {
        var owner:OwnershipAspect = cast cell.get(OwnershipAspect.id);

        if (hist[owner.isFilled] > 0 && hist[owner.occupier] > -1) {
            return true;
        } else if (false) { // TODO: Freshness
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
        // TODO: Freshness
        hist[owner.isFilled] = 0;
        hist[owner.occupier] = -1;
    }
}

