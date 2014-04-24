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
    static var nodeStateMap:Array<Null<NodeState>> = makeNodeStateMap();
    static var nodeEffectMap:Map<NodeState, Map<NodeState, Null<NodeEffect>>> = makeNodeEffectMap();

    var nodeVOs:Array<NodeVO>;
    var narrative:Array<NarrativeStep>;
    var lastStep:NarrativeStep;
    var maxFreshness:Int;
    
    var occupier_:AspectPtr;
    var isFilled_:AspectPtr;
    var head_:AspectPtr;
    var freshness_:AspectPtr;
    var maxFreshness_:AspectPtr;

    var headNodes:Array<AspectSet>;
    
    public function new(syncPeriod:Null<Float>, movePeriod:Null<Float>):Void {
        super(syncPeriod, movePeriod);
        updateSignal = new Zig();
        updateSignal.add(onUpdate);
        onAlert = addNarrativeStep;
    }

    override private function connect():Void {}
    override private function disconnect():Void endGame();
    override private function isMyTurn():Bool return false;
    
    private function onUpdate(event:GameEvent):Void {
        switch (event.type) {
            case RefereeAction(_): 
                processGameEventType(event.type);
                if (nodeVOs == null && game.plan != null) initNarrative();
            case _: 
                beginNarrative();
                processGameEventType(event.type);
                endNarrative();
        }
    }

    private inline function initNarrative():Void {
        // get props
        maxFreshness_ = game.plan.onState(FreshnessAspect.MAX_FRESHNESS);
        head_ = game.plan.onPlayer(BodyAspect.HEAD);
        occupier_ = game.plan.onNode(OwnershipAspect.OCCUPIER);
        isFilled_ = game.plan.onNode(OwnershipAspect.IS_FILLED);
        freshness_ = game.plan.onNode(FreshnessAspect.FRESHNESS);

        // initialize and populate narrative data structure
        nodeVOs = [];
        headNodes = [];
        var nodes:Array<AspectSet> = game.state.nodes;
        for (ike in 0...game.state.players.length) headNodes[ike] = game.state.nodes[game.state.players[ike][head_]];
        for (ike in 0...nodes.length) nodeVOs[ike] = makeNodeVO(ike);
        lastStep = {cause:null, nodeVOs:nodeVOs.copy()};
        narrative = [lastStep];
        maxFreshness = 0;
    }

    private inline function beginNarrative():Void {
        lastStep = {cause:null, nodeVOs:nodeVOs.copy()};
        narrative = [lastStep];
        maxFreshness = 0;
    }

    private inline function endNarrative():Void {
        var nodeVOsByFreshness:Array<NodeVO> = [];
        for (ike in 1...narrative.length) {
            var step:NarrativeStep = narrative[ike];
            for (nodeVO in step.nodeVOs) if (nodeVO != null) nodeVO.freshness /= maxFreshness;
            nodeVOsByFreshness = nodeVOsByFreshness.concat(step.nodeVOs.filter(isNotNull));
        }
        nodeVOsByFreshness.sort(whichNodeIsFresher);
        trace(nodeVOsByFreshness.join('\n'));
        trace(nodeVOsByFreshness.length);
        // Trigger the view stuff.
        trace(game.spitBoard());
    }

    private function isNotNull(vo:NodeVO):Bool return vo != null;

    private function whichNodeIsFresher(vo1:NodeVO, vo2:NodeVO):Int {
        var diff:Float = vo1.freshness - vo2.freshness;
        var val:Int = 0;
        if (diff < 0) val = -1;
        else if (diff > 0) val = 1;
        else val = 0;
        return val;
    }

    private function addNarrativeStep(cause:String):Void {

        if (narrative == null) return;

        // Append a step to the narrative.
        var nodes:Array<AspectSet> = game.state.nodes;
        var players:Array<AspectSet> = game.state.players;
        var step:NarrativeStep = null;
        // update the head table
        for (ike in 0...game.state.players.length) headNodes[ike] = nodes[game.state.players[ike][head_]];

        // Decay and Cavity rules should be narrated *simultaneously*
        if (cause == "CavityRule" && lastStep.cause == "DecayRule") {
            step = lastStep;
        } else {
            step = {nodeVOs:[], cause:cause};
            narrative.push(step);
        }

        for (ike in 0...players.length) headNodes[ike] = nodes[players[ike][head_]];
        for (ike in 0...nodes.length) {
            var freshness:Int = nodes[ike][freshness_];
            if (freshness == Aspect.NULL || freshness <= maxFreshness) continue;
            
            var next:NodeVO = makeNodeVO(ike, cause);
            next.effect = nodeEffectMap[nodeVOs[ike].state][next.state];
            nodeVOs[ike] = next;
            step.nodeVOs[ike] = next;
        }
        lastStep = step;

        var mF:Int = game.state.aspects[maxFreshness_];
        if (maxFreshness < mF) maxFreshness = mF;
    }

    private function makeNodeVO(id:Int, cause:String = null):NodeVO {
        var node:AspectSet = game.state.nodes[id];
        var occupier:Int = node[occupier_];
        var isFilled:Bool = node[isFilled_] == Aspect.TRUE;
        var isOccupied:Bool = occupier != Aspect.NULL;
        var isHead:Bool = occupier != Aspect.NULL && headNodes[occupier] == node;
        var freshness:Int = node[freshness_];
        
        var state:Null<NodeState> = nodeStateMap[(isOccupied ? 1 : 0) | (isFilled ? 2 : 0) | (isHead ? 4 : 0)];

        return {id:id, occupier:occupier, /*isHead:isHead, isFilled:isFilled, */freshness:freshness, state:state, cause:cause};
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
