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
    public var growGraph:Bool;
}

class DropPieceRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_:AspectPtr;
    @node(BodyAspect.BODY_PREV) var bodyPrev_:AspectPtr;
    @node(BodyAspect.NODE_ID) var nodeID_:AspectPtr;
    @node(FreshnessAspect.FRESHNESS) var freshness_:AspectPtr;
    @node(OwnershipAspect.IS_FILLED) var isFilled_:AspectPtr;
    @node(OwnershipAspect.OCCUPIER) var occupier_:AspectPtr;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_:AspectPtr;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_:AspectPtr;
    @state(PieceAspect.PIECE_TABLE_ID) var pieceTableID_:AspectPtr;
    @state(PieceAspect.PIECE_REFLECTION) var pieceReflection_:AspectPtr;
    @state(PieceAspect.PIECE_ROTATION) var pieceRotation_:AspectPtr;
    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_:AspectPtr;

    private var cfg:DropPieceConfig;

    public function new(cfg:DropPieceConfig):Void {
        super();
        this.cfg = cfg;
    }

    override public function update():Void {

        var dropOptions:Array<DropPieceOption> = [];

        // get current player head
        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var bodyNode:BoardNode = state.nodes[state.players[currentPlayer].at(bodyFirst_)];

        // Find edge nodes of current player
        var edgeNodes:Array<BoardNode> = bodyNode.boardListToArray(state.nodes, bodyNext_).filter(isFreeEdge).array();

        var pieceGroups:Array<PieceGroup> = [Pieces.getPieceById(state.aspects.at(pieceTableID_))];
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
                                targetNode:node.value.at(nodeID_),
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
        var pieceGroups:Array<PieceGroup> = [Pieces.getPieceById(state.aspects.at(pieceTableID_))];
        var node:BoardNode = state.nodes[option.targetNode];
        var coords:Array<IntCoord> = pieceGroups[option.pieceID][option.reflection][option.rotation][0];
        var homeCoord:IntCoord = coords[0];
        var maxFreshness:Int = state.aspects.at(maxFreshness_) + 1;

        var currentPlayer:Int = state.aspects.at(currentPlayer_);
        var bodyNode:BoardNode = state.nodes[state.players[currentPlayer].at(bodyFirst_)];

        for (coord in coords) bodyNode = fillAndOccupyCell(walkNode(node, coord, homeCoord), currentPlayer, maxFreshness, bodyNode);
        state.players[currentPlayer].mod(bodyFirst_, bodyNode.value.at(nodeID_));

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
        if (me.at(occupier_) != currentPlayer || me.at(isFilled_) == Aspect.FALSE) me.mod(freshness_, maxFreshness);
        me.mod(occupier_, currentPlayer);
        me.mod(isFilled_, Aspect.TRUE);
        return bodyNode.addNode(node, state.nodes, nodeID_, bodyNext_, bodyPrev_);
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

