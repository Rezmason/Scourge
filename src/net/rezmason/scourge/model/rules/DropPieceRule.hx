/*
- Find edge nodes of current player

A: For each available piece,
    B: For each of the piece's reflections,
        C: For each of the reflection's angles,
            Create coord list
            D: For each of the angle's neighbor coords,
                E: For each edge node of the current player,
                    If the node under the first piece coord is not in the coord list,
                        Add it to the list
                        For each of the angle's piece coords,
                            If the node under the coord is occupied,
                                continue C
                        Create option from angle and first piece coord
                            Remember the ID
*/

package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.PieceAspect;

using Lambda;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

typedef DropPieceConfig = {
    public var overlapSelf:Bool;
}

class DropPieceRule extends Rule {

    static var nodeReqs:AspectRequirements;
    static var playerReqs:AspectRequirements;
    static var stateReqs:AspectRequirements;

    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var head_:AspectPtr;
    var currentPlayer_:AspectPtr;
    var pieceID_:AspectPtr;

    var overlapSelf:Bool;

    private var cfg:DropPieceConfig;

    public function new(cfg:DropPieceConfig):Void {
        super();
        this.cfg = cfg;

        if (nodeReqs == null)  nodeReqs = [
            OwnershipAspect.IS_FILLED,
            OwnershipAspect.OCCUPIER,
        ];

        if (playerReqs == null) playerReqs = [
            BodyAspect.HEAD,
        ];

        if (stateReqs == null) stateReqs = [
            PlyAspect.CURRENT_PLAYER,
            PieceAspect.PIECE_ID,
        ];
    }

    override public function init(state:State):Void {
        super.init(state);
        occupier_ = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        head_ =   state.playerAspectLookup[BodyAspect.HEAD.id];
        currentPlayer_ = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        pieceID_ = state.stateAspectLookup[PieceAspect.PIECE_ID.id];

        overlapSelf = cfg.overlapSelf;
    }

    override public function listStateAspectRequirements():AspectRequirements { return stateReqs; }
    override public function listPlayerAspectRequirements():AspectRequirements { return playerReqs; }
    override public function listBoardAspectRequirements():AspectRequirements { return nodeReqs; }


    override public function getOptions():Array<Option> {
        return [];
    }

    override public function chooseOption(choice:Option):Void {

    }

    /*
    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (history.get(me.at(isFilled_)) == 0) return false;
        return history.get(me.at(occupier_)) == history.get(you.at(occupier_));
    }

    function eatCell(me:AspectSet, currentPlayer:Int):Void {
        history.set(me.at(occupier_), currentPlayer);
        history.set(me.at(freshness_), 1);
    }
    */
}

class DropPieceOption extends Option {

    public function new():Void {
        super();

    }
}

