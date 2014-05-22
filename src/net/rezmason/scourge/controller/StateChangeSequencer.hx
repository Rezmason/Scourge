package net.rezmason.scourge.controller;

import net.rezmason.scourge.controller.ControllerTypes;
import net.rezmason.scourge.model.Game;
import net.rezmason.utils.Zig;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.RopesTypes;
using net.rezmason.ropes.StatePlan;
using net.rezmason.scourge.model.BoardUtils;

import net.rezmason.scourge.model.aspects.*;

class StateChangeSequencer extends PlayerSystem implements Spectator {

    public var updateSignal(default, null):Zig<GameEvent->Void>;
    public var sequenceStartSignal(default, null):Zig<Int->Array<NodeVO>->Void>;
    public var sequenceUpdateSignal(default, null):Zig<Int->Array<SequenceStep>->Void>;
    static var nodeStateMap:Array<Null<NodeState>> = makeNodeStateMap();
    static var nodeEffectMap:Map<NodeState, Map<NodeState, Null<NodeEffect>>> = makeNodeEffectMap();

    var nodeVOs:Array<NodeVO>;
    var sequence:Array<SequenceStep>;
    var lastStep:SequenceStep;
    var maxFreshness:Int;
    
    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var head_:AspectPtr;
    var freshness_:AspectPtr;
    var maxFreshness_:AspectPtr;

    var nodePool:Array<NodeVO>;
    var stepPool:Array<SequenceStep>;

    var headNodes:Array<AspectSet>;
    
    public function new():Void {
        super();
        updateSignal = new Zig();
        sequenceStartSignal = new Zig();
        sequenceUpdateSignal = new Zig();
        updateSignal.add(onUpdate);
        onAlert = addSequenceStep;
        nodePool = [];
        stepPool = [];
    }

    override private function connect():Void {}
    override private function disconnect():Void endGame();
    
    override private function init(configData:String, saveData:String):Void {
        super.init(configData, saveData);
        initSequence();
    }
    
    override private function isMyTurn():Bool return false;
    
    private function onUpdate(event:GameEvent):Void {
        switch (event.type) {
            case RefereeAction(type): 
                processGameEventType(event.type);
            case _:
                beginSequence();
                processGameEventType(event.type);
                endSequence();
                if (game.winner != Aspect.NULL) destroySequence();
        }
    }

    private inline function initSequence():Void {
        // get props
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
        for (ike in 0...nodes.length) nodeVOs[ike] = getNodeVO(ike);
        lastStep = getStep(nodeVOs.copy());
        sequence = [lastStep];
        maxFreshness = 0;

        sequenceStartSignal.dispatch(game.state.players.length, nodeVOs);
    }

    private inline function beginSequence():Void {
        poolObjects();
        lastStep = getStep(nodeVOs.copy());
        sequence = [lastStep];
        maxFreshness = 0;
    }

    private inline function endSequence():Void {
        var nodeVOsByFreshness:Array<NodeVO> = [];
        for (ike in 1...sequence.length) {
            var step:SequenceStep = sequence[ike];
            nodeVOsByFreshness = nodeVOsByFreshness.concat(step.nodeVOs.filter(isNotNull));
        }
        nodeVOsByFreshness.sort(whichNodeIsFresher);
        trace(nodeVOsByFreshness.join('\n'));
        trace(sequence.length);
        trace(game.spitBoard());
        
        // Trigger the view stuff.

        sequenceUpdateSignal.dispatch(maxFreshness, sequence);
    }

    private inline function destroySequence():Void {
        poolObjects(true);
        nodeVOs = null;
        sequence = null;
    }

    private inline function poolObjects(grabAll:Bool = false):Void {
        if (sequence != null) {
            for (step in sequence) {
                for (ike in 0...step.nodeVOs.length) {
                    var vo:NodeVO = step.nodeVOs[ike];
                    if (vo != null && (grabAll || nodeVOs[ike] != vo)) nodePool.push(vo);
                }
                stepPool.push(step);
            }
        }
    }

    private function isNotNull(vo:NodeVO):Bool return vo != null;

    private function whichNodeIsFresher(vo1:NodeVO, vo2:NodeVO):Int {
        var diff:Int = vo1.freshness - vo2.freshness;
        var val:Int = 0;
        if (diff < 0) val = -1;
        else if (diff > 0) val = 1;
        else val = 0;
        return val;
    }

    private function addSequenceStep(cause:String):Void {

        if (sequence == null) return;


        // Append a step to the sequence.
        var nodes:Array<AspectSet> = game.state.nodes;
        var players:Array<AspectSet> = game.state.players;
        var step:SequenceStep = null;
        // update the head table
        for (ike in 0...game.state.players.length) headNodes[ike] = nodes[game.state.players[ike][head_]];

        // Decay and Cavity rule changes should be timed *simultaneously*
        if (cause == "CavityRule" && lastStep.cause == "DecayRule") {
            step = lastStep;
        } else {
            step = getStep([], cause);
            sequence.push(step);
        }

        for (ike in 0...players.length) headNodes[ike] = nodes[players[ike][head_]];
        for (ike in 0...nodes.length) {
            var freshness:Int = nodes[ike][freshness_];
            if (freshness == Aspect.NULL || freshness <= maxFreshness) continue;
            
            var next:NodeVO = getNodeVO(ike, cause);
            next.effect = nodeEffectMap[nodeVOs[ike].state][next.state];
            nodeVOs[ike] = next;
            step.nodeVOs[ike] = next;
        }
        lastStep = step;

        var mF:Int = game.state.aspects[maxFreshness_];
        if (maxFreshness < mF) maxFreshness = mF;

    }

    private function getNodeVO(id:Int, cause:String = null):NodeVO {
        var vo:NodeVO = nodePool.pop();
        if (vo == null) vo = {id:0, occupier:0, lastOccupier:0, freshness:0, state:Empty, cause:null};
        var node:AspectSet = game.state.nodes[id];
        
        var occupier:Int = node[occupier_];
        var isFilled:Bool = node[isFilled_] == Aspect.TRUE;
        var isOccupied:Bool = occupier != Aspect.NULL;
        var isHead:Bool = occupier != Aspect.NULL && headNodes[occupier] == node;
        
        vo.id = id;
        vo.cause = cause;
        vo.occupier = occupier;
        vo.lastOccupier = (nodeVOs[id] != null) ? nodeVOs[id].occupier : occupier;
        vo.freshness = node[freshness_];
        vo.state = nodeStateMap[(isOccupied ? 1 : 0) | (isFilled ? 2 : 0) | (isHead ? 4 : 0)];

        return vo;
    }

    private function getStep(nodeVOs:Array<NodeVO>, cause:String = null):SequenceStep {
        var step:SequenceStep = stepPool.pop();
        if (step == null) {
            step = {cause:cause, nodeVOs:nodeVOs};
        } else {
            step.cause = cause;
            step.nodeVOs = nodeVOs;
        }
        return step;
    }

    static function makeNodeStateMap():Array<Null<NodeState>> return [Empty, Cavity, Wall, Body, null, null, null, Head,];

    static function makeNodeEffectMap():Map<NodeState, Map<NodeState, Null<NodeEffect>>> {
        return [
            Empty => [Cavity => CavityFadesIn, Body => PieceDropsDown,],
            Cavity => [Empty => CavityFadesOut, Cavity => CavityFadesOver, Body => PieceDropsDown,],
            Wall => [Wall => null],
            Body => [Empty => BodyKilled, Cavity => BodyKilled, Body => BodyEaten,],
            Head => [Empty => HeadKilled, Cavity => HeadKilled, Body => HeadEaten,],
        ];
    }
}
