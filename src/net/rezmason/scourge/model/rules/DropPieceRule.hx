package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.PieceTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PieceAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

typedef DropPieceConfig = {
    public var overlapSelf:Bool;
    public var allowFlipping:Bool;
    public var allowRotating:Bool;
}

class DropPieceRule extends Rule {

    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var freshness_:AspectPtr;
    var head_:AspectPtr;
    var currentPlayer_:AspectPtr;
    var pieceID_:AspectPtr;

    var pieceReflection_:AspectPtr;
    var pieceRotation_:AspectPtr;

    var bodyFirst_:AspectPtr;
    var bodyNext_:AspectPtr;

    private var cfg:DropPieceConfig;

    public function new(cfg:DropPieceConfig):Void {
        super();
        this.cfg = cfg;

        stateAspectRequirements = [
            PlyAspect.CURRENT_PLAYER,
            PieceAspect.PIECE_ID,
            PieceAspect.PIECE_REFLECTION,
            PieceAspect.PIECE_ROTATION,
        ];

        playerAspectRequirements = [
            BodyAspect.HEAD,
        ];

        nodeAspectRequirements = [
            OwnershipAspect.IS_FILLED,
            OwnershipAspect.OCCUPIER,
            FreshnessAspect.FRESHNESS,
        ];
    }

    override public function init(state:State):Void {
        super.init(state);

        head_ =   state.playerAspectLookup[BodyAspect.HEAD.id];
        freshness_ = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        occupier_ = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        currentPlayer_ = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        pieceID_ = state.stateAspectLookup[PieceAspect.PIECE_ID.id];
        pieceReflection_ = state.stateAspectLookup[PieceAspect.PIECE_REFLECTION.id];
        pieceRotation_ = state.stateAspectLookup[PieceAspect.PIECE_ROTATION.id];

        bodyFirst_ = state.nodeAspectLookup[BodyAspect.BODY_FIRST.id];
        bodyNext_ = state.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
    }

    override public function update():Void {

        var dropOptions:Array<DropPieceOption> = [];

        // get current player head
        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));
        var head:Int = history.get(state.players[currentPlayer].at(head_));
        var playerHead:BoardNode = state.nodes[head];

        // Find edge nodes of current player
        var edgeNodes:Array<BoardNode> = playerHead.getGraph(true, isLivingBodyNeighbor);
        edgeNodes = edgeNodes.filter(isFreeEdge).array();

        var pieceGroups:Array<PieceGroup> = [Pieces.getPieceById(history.get(state.aspects.at(pieceID_)))];
        var pieceReflection:Int = history.get(state.aspects.at(pieceReflection_));
        var pieceRotation:Int = history.get(state.aspects.at(pieceRotation_));

        for (pieceIndex in 0...pieceGroups.length) {

            var PieceGroup:PieceGroup = pieceGroups[pieceIndex];

            var allowedReflectionIndex:Int = pieceReflection % PieceGroup.length;
            for (reflectionIndex in 0...PieceGroup.length) {

                if (!cfg.allowFlipping && reflectionIndex != allowedReflectionIndex) continue;
                var reflection:Array<Piece> = PieceGroup[reflectionIndex];

                var allowedRotationIndex:Int = pieceRotation % reflection.length;
                for (rotationIndex in 0...reflection.length) {

                    if (!cfg.allowRotating && rotationIndex != allowedRotationIndex) continue;
                    var rotation:Piece = reflection[rotationIndex];

                    var touchedNodes:Array<BoardNode> = [];

                    var coords:Array<IntCoord> = rotation[0];
                    var homeCoord:IntCoord = coords[0];

                    for (node in edgeNodes) {
                        for (neighborCoord in rotation[1]) {
                            var nodeAtCoord:BoardNode = walkNode(node, neighborCoord, homeCoord);
                            if (!touchedNodes.has(nodeAtCoord)) touchedNodes.push(nodeAtCoord);
                        }

                        if (cfg.overlapSelf) {
                            for (coord in rotation[0]) {
                                var nodeAtCoord:BoardNode = walkNode(node, coord, homeCoord);
                                if (!touchedNodes.has(nodeAtCoord)) touchedNodes.push(nodeAtCoord);
                            }
                        }
                    }

                    for (node in touchedNodes) {
                        var valid:Bool = true;

                        for (coord in coords) {
                            var occupier:Int = history.get(walkNode(node, homeCoord, coord).value.at(occupier_));
                            if (occupier > 0 && !(cfg.overlapSelf && occupier == currentPlayer)) {
                                valid = false;
                                break;
                            }
                        }

                        if (valid) {
                            dropOptions.push({
                                targetNode:node.id,
                                pieceID:pieceIndex,
                                rotation:rotationIndex,
                                reflection:reflectionIndex,
                                optionID:dropOptions.length,
                            });
                        }
                    }
                }
            }
        }

        options = cast dropOptions;
    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

        var option:DropPieceOption = cast options[choice];
        var pieceGroups:Array<PieceGroup> = [Pieces.getPieceById(history.get(state.aspects.at(pieceID_)))];
        var node:BoardNode = state.nodes[option.targetNode];
        var coords:Array<IntCoord> = pieceGroups[option.pieceID][option.reflection][option.rotation][0];
        var homeCoord:IntCoord = coords[0];

        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));

        for (coord in coords) fillAndOccupyCell(walkNode(node, coord, homeCoord).value, currentPlayer);
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (history.get(me.at(isFilled_)) == 0) return false;
        return history.get(me.at(occupier_)) == history.get(you.at(occupier_));
    }

    inline function isFreeEdge(node:BoardNode):Bool {
        return node.neighbors.exists(isVacant);
    }

    inline function isVacant(node:BoardNode):Bool {
        return history.get(node.value.at(isFilled_)) == 0;
    }

    function fillAndOccupyCell(me:AspectSet, currentPlayer:Int):Void {

        if (history.get(me.at(occupier_)) != currentPlayer || history.get(me.at(isFilled_)) == 0) {
            // Only freshen it if it's fresh
            history.set(me.at(freshness_), 1);
        }

        history.set(me.at(occupier_), currentPlayer);
        history.set(me.at(isFilled_), 1);
    }

    function walkNode(node:BoardNode, fromCoord:IntCoord, toCoord:IntCoord):BoardNode {
        var dn:Int = 0;
        var dw:Int = 0;
        var de:Int = toCoord[0] - fromCoord[0];
        var ds:Int = toCoord[1] - fromCoord[1];

        if (de < 0) {
            dw = -de;
            de = 0;
        }

        if (ds < 0) {
            dn = -ds;
            ds = 0;
        }

        return node.run(Gr.n, dn).run(Gr.s, ds).run(Gr.e, de).run(Gr.w, dw);
    }
}

typedef DropPieceOption = {>Option,
    var targetNode:Int;
    var pieceID:Int;
    var rotation:Int;
    var reflection:Int;
}

