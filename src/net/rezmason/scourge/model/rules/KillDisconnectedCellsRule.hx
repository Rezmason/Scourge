package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
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

    override public function getOptions(state:State):Array<Option> { return [option]; }

    override public function chooseOption(state:State, choice:Option):Void {

        var history:History<Int> = state.history;

        if (choice == option) {

            function isCandidate(cell:Aspects, connection:Aspects):Bool {
                var owner:OwnershipAspect = cast cell.get(OwnershipAspect.id);
                var fresh:FreshnessAspect = cast cell.get(FreshnessAspect.id);

                if (history.get(owner.isFilled) > 0 && history.get(owner.occupier) > -1) {
                    return true;
                } else if (history.get(fresh.freshness) > 0) {
                    return true;
                }

                return false;
            }

            function isLivingBodyNeighbor(cell:Aspects, connection:Aspects):Bool {
                var owner1:OwnershipAspect = cast cell.get(OwnershipAspect.id);
                var owner2:OwnershipAspect = cast connection.get(OwnershipAspect.id);
                return history.get(owner1.isFilled) > 0 && history.get(owner1.occupier) == history.get(owner2.occupier);
            }

            function killCell(cell:Aspects):Void {
                var owner:OwnershipAspect = cast cell.get(OwnershipAspect.id);
                var fresh:FreshnessAspect = cast cell.get(FreshnessAspect.id);
                history.set(fresh.freshness, 0);
                history.set(owner.isFilled, 0);
                history.set(owner.occupier, -1);
            }

            // perform kill operation on state

            var nodesInPlay:Array<BoardNode> = [];

            var heads:Array<BoardNode> = [];
            for (player in state.players) {
                var body:BodyAspect = cast player.get(BodyAspect.id);
                heads.push(state.nodes[history.get(body.head)]);
            }

            var candidates:Array<BoardNode> = heads.expandGraph(true, isCandidate);
            var livingBodyNeighbors:Array<BoardNode> = heads.expandGraph(true, isLivingBodyNeighbor);

            for (candidate in candidates) {
                if (!livingBodyNeighbors.has(candidate)) killCell(candidate.value);
            }
        }
    }
}

