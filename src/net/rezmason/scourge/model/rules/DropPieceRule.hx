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
using net.rezmason.scourge.model.BoardUtils;
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
    var maxFreshness_:AspectPtr;
    var currentPlayer_:AspectPtr;
    var pieceID_:AspectPtr;

    var pieceReflection_:AspectPtr;
    var pieceRotation_:AspectPtr;

    var bodyFirst_:AspectPtr;
    var bodyNext_:AspectPtr;
    var bodyPrev_:AspectPtr;

    private var cfg:DropPieceConfig;

    public function new(cfg:DropPieceConfig):Void {
        super();
        this.cfg = cfg;

        stateAspectRequirements = [
            PlyAspect.CURRENT_PLAYER,
            PieceAspect.PIECE_ID,
            PieceAspect.PIECE_REFLECTION,
            PieceAspect.PIECE_ROTATION,
            FreshnessAspect.MAX_FRESHNESS,
        ];

        playerAspectRequirements = [
            BodyAspect.HEAD,
            BodyAspect.BODY_FIRST,
        ];

        nodeAspectRequirements = [
            OwnershipAspect.IS_FILLED,
            OwnershipAspect.OCCUPIER,
            FreshnessAspect.FRESHNESS,
            BodyAspect.BODY_NEXT,
            BodyAspect.BODY_PREV,
        ];
    }

    override public function init(state:State):Void {
        super.init(state);

        freshness_ = state.nodeAspectLookup[FreshnessAspect.FRESHNESS.id];
        maxFreshness_ = state.stateAspectLookup[FreshnessAspect.MAX_FRESHNESS.id];
        occupier_ = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        isFilled_ = state.nodeAspectLookup[OwnershipAspect.IS_FILLED.id];
        currentPlayer_ = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        pieceID_ = state.stateAspectLookup[PieceAspect.PIECE_ID.id];
        pieceReflection_ = state.stateAspectLookup[PieceAspect.PIECE_REFLECTION.id];
        pieceRotation_ = state.stateAspectLookup[PieceAspect.PIECE_ROTATION.id];

        bodyFirst_ = state.playerAspectLookup[BodyAspect.BODY_FIRST.id];
        bodyNext_ = state.nodeAspectLookup[BodyAspect.BODY_NEXT.id];
        bodyPrev_ = state.nodeAspectLookup[BodyAspect.BODY_PREV.id];
    }

    override public function update():Void {

        var dropOptions:Array<DropPieceOption> = [];

        // get current player head
        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var bodyNode:BoardNode = state.nodes[state.players[currentPlayer].at(bodyFirst_)];

        // Find edge nodes of current player
        var edgeNodes:Array<BoardNode> = bodyNode.boardListToArray(state.nodes, bodyNext_).filter(isFreeEdge).array();

        var pieceGroups:Array<PieceGroup> = [Pieces.getPieceById(state.aspects.at(pieceID_))];
        var pieceReflection:Int = state.aspects.at(pieceReflection_);
        var pieceRotation:Int = state.aspects.at(pieceRotation_);

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
                            var occupier:Int = walkNode(node, homeCoord, coord).value.at(occupier_);
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
        var pieceGroups:Array<PieceGroup> = [Pieces.getPieceById(state.aspects.at(pieceID_))];
        var node:BoardNode = state.nodes[option.targetNode];
        var coords:Array<IntCoord> = pieceGroups[option.pieceID][option.reflection][option.rotation][0];
        var homeCoord:IntCoord = coords[0];
        var maxFreshness:Int = state.aspects.at(maxFreshness_) + 1;

        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var bodyNode:BoardNode = state.nodes[state.players[currentPlayer].at(bodyFirst_)];

        for (coord in coords) bodyNode = fillAndOccupyCell(walkNode(node, coord, homeCoord), currentPlayer, maxFreshness, bodyNode);
        state.players[currentPlayer].mod(bodyFirst_, bodyNode.id);

        state.aspects.mod(maxFreshness_, maxFreshness);
    }

    inline function isFreeEdge(node:BoardNode):Bool {
        return node.neighbors.exists(isVacant);
    }

    inline function isVacant(node:BoardNode):Bool {
        return node.value.at(isFilled_) == Aspect.FALSE;
    }

    inline function fillAndOccupyCell(node:BoardNode, currentPlayer:Int, maxFreshness, bodyNode:BoardNode):BoardNode {

        var me:AspectSet = node.value;

        if (me.at(occupier_) != currentPlayer || me.at(isFilled_) == Aspect.FALSE) {
            me.mod(freshness_, maxFreshness);
        }

        me.mod(occupier_, currentPlayer);
        me.mod(isFilled_, Aspect.TRUE);

        return bodyNode.addNode(node, state.nodes, bodyNext_, bodyPrev_);
    }

    inline function walkNode(node:BoardNode, fromCoord:IntCoord, toCoord:IntCoord):BoardNode {
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

