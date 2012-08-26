package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;

using Lambda;

using net.rezmason.scourge.model.GridUtils;

class EatCellsRule extends Rule {

    static var nodeReqs:AspectRequirements;
    static var playerReqs:AspectRequirements;
    static var option:Option = new Option();

    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var freshness_:AspectPtr;
    var head_:AspectPtr;

    private var cfg:EatCellsConfig;

    public function new(cfg:EatCellsConfig):Void {
        super();
        this.cfg = cfg;

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

    override public function chooseOption(choice:Option):Void {
        if (choice == option) {

            // perform eat operation on state

            // Get all fresh nodes from FRESH_NEXT

            // for every node in the fresh nodes list,
                // for every direction,
                    // walk in that direction:
                        // if the current node is eatable,
                            // add it to the pending list
                        // else if the current node is owned by you,
                            // for each pending node,
                                // convert to fresh node owned by you
                                // if recursive,
                                    // add node to fresh nodes list
                            // break
                        // else
                            // break


        }
    }

    /*
    function isCandidate(me:AspectSet, you:AspectSet):Bool {
        var occupier:Int = history.get(me[occupier_]);
        var isFilled:Int = history.get(me[isFilled_]);
        var freshness:Int = history.get(me[freshness_]);
        if (isFilled > 0 && occupier > -1) return true;
        else if (freshness > 0) return true;
        return false;
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (history.get(me[isFilled_]) == 0) return false;
        return history.get(me[occupier_]) == history.get(you[occupier_]);
    }

    function killCell(me:AspectSet):Void {
        history.set(me[occupier_], -1);
        history.set(me[isFilled_], 0);
        history.set(me[freshness_], 0);
    }
    */
}

