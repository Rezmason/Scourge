package net.rezmason.scourge.controller;

import net.rezmason.ds.ShitList;
import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.Game;
import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.GridLocus;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.scourge.model.aspects.*;
import net.rezmason.utils.Zig;

using net.rezmason.ropes.StatePlan;
using net.rezmason.ropes.GridUtils;
using net.rezmason.utils.Pointers;

class StateChangeSequencer implements IPlayerMediator {

    public inline static var NO_CAUSE:String = "";
    public var sequenceStartSignal(default, null):Zig<Int->Array<XYZ>->Void>;
    public var sequenceUpdateSignal(default, null):Zig<Int->Array<String>->Array<Array<NodeVO>>->Array<Int>->Array<Int>->Void>;
    public var proceedSignal(default, null):Zig<Void->Void>;
    static var nodeStateMap:Array<NodeState> = makeNodeStateMap();

    var nodeVOs:Array<NodeVO>;
    var steps:Array<Array<NodeVO>>;
    var causes:Array<String>;
    var lastStep:Array<NodeVO>;
    var lastCause:String;
    var maxFreshness:Int;
    
    var ident_:AspectPtr;
    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var head_:AspectPtr;
    var freshness_:AspectPtr;
    var maxFreshness_:AspectPtr;

    var headNodes:Array<AspectSet>;

    var game:Game;
    
    public function new():Void {
        sequenceStartSignal = new Zig();
        sequenceUpdateSignal = new Zig();
        proceedSignal = new Zig();
    }

    public function connect(game:Game):Void {
        this.game = game;
        initSequence();
    }
    
    private inline function initSequence():Void {
        // get props
        ident_ = Ptr.intToPointer(0, game.state.key);
        maxFreshness_ = game.plan.onState(FreshnessAspect.MAX_FRESHNESS);
        head_ = game.plan.onPlayer(BodyAspect.HEAD);
        occupier_ = game.plan.onNode(OwnershipAspect.OCCUPIER);
        isFilled_ = game.plan.onNode(OwnershipAspect.IS_FILLED);
        freshness_ = game.plan.onNode(FreshnessAspect.FRESHNESS);

        // initialize and populate sequence data structure
        nodeVOs = [];
        headNodes = [];
        var nodes:Array<AspectSet> = game.state.nodes;
        for (ike in 0...game.state.players.length) headNodes[ike] = game.state.nodes[game.state.players[ike][head_]];
        for (ike in 0...nodes.length) nodeVOs[ike] = getNodeVO(nodes[ike], null);
        lastStep = nodeVOs.copy();
        steps = [lastStep];
        lastCause = NO_CAUSE;
        causes = [lastCause];
        maxFreshness = 0;

        sequenceStartSignal.dispatch(game.state.players.length, getNodePositions());
        sequenceUpdateSignal.dispatch(1, causes, steps, getDistancesFromHead(), getNeighborBitfields());
    }

    public function moveStarts():Void {
        lastStep = nodeVOs.copy();
        steps = [lastStep];
        lastCause = NO_CAUSE;
        causes = [lastCause];
        maxFreshness = 0;
    }

    public function moveStops():Void {
        sequenceUpdateSignal.dispatch(maxFreshness, causes, steps, getDistancesFromHead(), getNeighborBitfields());
    }

    public function disconnect():Void {
        nodeVOs = null;
        steps = null;
        game = null;
    }

    public function moveSteps(cause:String):Void {

        if (steps == null) return;

        // Append a step to the sequence.
        var nodes:Array<AspectSet> = game.state.nodes;
        var players:Array<AspectSet> = game.state.players;
        var step:Array<NodeVO> = null;
        // update the head table
        for (ike in 0...game.state.players.length) headNodes[ike] = nodes[game.state.players[ike][head_]];

        step = [];
        steps.push(step);
        causes.push(cause);
        lastStep = step;
        lastCause = cause;

        for (ike in 0...players.length) headNodes[ike] = nodes[players[ike][head_]];
        for (ike in 0...nodes.length) {
            var freshness:Int = nodes[ike][freshness_];
            if (freshness == Aspect.NULL || freshness <= maxFreshness) continue;
            //trace('$freshness $maxFreshness');
            
            var next:NodeVO = getNodeVO(nodes[ike], nodeVOs[ike]);
            nodeVOs[ike] = next;
            step.push(next);
        }
        step.sort(whichNodeIsFresher);

        var mF:Int = game.state.globals[maxFreshness_];
        if (maxFreshness < mF) maxFreshness = mF;

    }

    private function whichNodeIsFresher(vo1:NodeVO, vo2:NodeVO):Int {
        var diff:Int = vo1.freshness - vo2.freshness;
        var val:Int = 0;
        if (diff < 0) val = -1;
        else if (diff > 0) val = 1;
        else val = 0;
        return val;
    }

    private function getNodeVO(node:AspectSet, lastNodeVO:NodeVO):NodeVO {
        var id:Int = node[ident_];
        var occupier:Int = node[occupier_];
        var isFilled:Bool = node[isFilled_] == Aspect.TRUE;
        var isOccupied:Bool = occupier != Aspect.NULL;
        var isHead:Bool = occupier != Aspect.NULL && headNodes[occupier] == node;

        var vo:NodeVO = {
            id:id,
            occupier:occupier, 
            freshness:node[freshness_], 
            state:nodeStateMap[(isOccupied ? 1 : 0) | (isFilled ? 2 : 0) | (isHead ? 4 : 0)], 
        };

        return vo;
    }

    private function getDistancesFromHead():Array<Int> {
        var nodes:Array<AspectSet> = game.state.nodes;
        var loci:Array<BoardLocus> = game.state.loci;
        var distances:Array<Int> = [];
        var maxDistance:Int = 0;
        for (ike in 0...nodes.length) distances[ike] = -1;
        for (ike in 0...headNodes.length) {
            var node:AspectSet = headNodes[ike];
            if (node != null) {
                var playerID:Int = node[occupier_];
                distances[node[ident_]] = -2;
                var pendingNodes:List<AspectSet> = new List<AspectSet>();
                while (node != null) {
                    var nodeID:Int = node[ident_];
                    var distance:Int = distances[node[ident_]];
                    if (maxDistance < distance) maxDistance = distance;

                    for (neighborLocus in loci[nodeID].orthoNeighbors()) {
                        if (neighborLocus != null) {
                            var neighbor:AspectSet = neighborLocus.value;
                            var neighborID:Int = neighbor[ident_];
                            if (neighbor[occupier_] == playerID && neighbor[isFilled_] == Aspect.TRUE) {
                                if (distances[neighborID] == -1) {
                                    distances[neighborID] = distance + 2;
                                    pendingNodes.add(neighbor);
                                }
                            }
                        }
                    }

                    for (neighborLocus in loci[nodeID].diagNeighbors()) {
                        if (neighborLocus != null) {
                            var neighbor:AspectSet = neighborLocus.value;
                            var neighborID:Int = neighbor[ident_];
                            if (neighbor[occupier_] == playerID && neighbor[isFilled_] == Aspect.TRUE) {
                                if (distances[neighborID] == -1) {
                                    distances[neighborID] = distance + 3;
                                    pendingNodes.add(neighbor);
                                }
                            }
                        }
                    }

                    node = pendingNodes.pop();
                }
            }
        }
        return distances;
    }

    private function getNeighborBitfields():Array<Int> {
        var nodes:Array<AspectSet> = game.state.nodes;
        var neighborBitfields:Array<Int> = [];
        
        for (ike in 0...nodes.length) {
            if (nodes[ike][isFilled_] == Aspect.TRUE && nodes[ike][occupier_] == Aspect.NULL) {
                var isVisible:Bool = false;
                for (neighborLocus in game.state.loci[ike].neighbors) {
                    if (neighborLocus == null) continue;
                    if (neighborLocus.value[isFilled_] == Aspect.FALSE || neighborLocus.value[occupier_] != Aspect.NULL) {
                        isVisible = true;
                        break;
                    }
                }
                if (!isVisible) neighborBitfields[ike] = -1;
            }
        }

        for (ike in 0...nodes.length) {
            if (neighborBitfields[ike] == -1) continue;
            var itr:Int = 0;
            var bitfield:Int = 0;
            var playerID:Int = nodes[ike][occupier_];
            if (nodes[ike][isFilled_] == Aspect.TRUE) {
                for (neighborLocus in game.state.loci[ike].orthoNeighbors()) {
                    var val:Int = 0;
                    if (neighborLocus != null) {
                        var neighborNode:AspectSet = neighborLocus.value;
                        if (neighborBitfields[neighborNode[ident_]] == -1) val = 0;
                        else if (neighborNode[isFilled_] == Aspect.TRUE && neighborNode[occupier_] == playerID) val = 1;
                    }
                    bitfield = bitfield | (val << itr);
                    itr++;
                }
            }
            neighborBitfields[ike] = bitfield;
        }
        return neighborBitfields;
    }

    private function getNodePositions():Array<XYZ> {
        var positions:Array<XYZ> = [];
        var grid:BoardLocus = game.state.loci[0].run(Gr.s).run(Gr.w);
        var y:Float = 0;
        var x:Float = 0;
        for (row in grid.walk(Gr.n)) {
            x = 0;
            for (column in row.walk(Gr.e)) {
                positions[column.value[ident_]] = {x:x, y:y, z:0};
                x++;
            }
            y++;
        }

        for (ike in 0...positions.length) {
            var position:XYZ = positions[ike];
            position.x = (position.x - (x - 1) / 2) * 0.07;
            position.y = (position.y - (x - 1) / 2) * 0.07;
            position.z = (position.x * position.x + position.y * position.y) * -0.2;
            if (game.state.nodes[ike][isFilled_] == Aspect.TRUE) position.z *= 0.96;
        }
        return positions;
    }

    static function makeNodeStateMap():Array<NodeState> return [Empty, Cavity, Wall, Body, null, null, null, Head,];
}
