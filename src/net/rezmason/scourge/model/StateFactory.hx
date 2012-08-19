package net.rezmason.scourge.model;

import haxe.FastList;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.Aspect;

using Lambda;
using Std;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.IntHashUtils;

class StateFactory {
    public function new():Void {

    }

    public function makeState(cfg:StateConfig, history:History<Int>):State {
        if (cfg == null) return null;
        if (cfg.playerGenes == null) return null;
        if (cfg.playerHeads == null) return null;
        if (cfg.rules == null) return null;

        var allocator:HistoryAllocator = history.alloc;

        var state:State = new State(history.array);

        var rules:Array<Rule> = cfg.rules;
        while (rules.has(null)) rules.remove(null);

        // Create and populate the aspect requirement lists
        var stateRequirements:AspectRequirements = new AspectRequirements();
        var playerRequirements:AspectRequirements = new AspectRequirements();
        var boardRequirements:AspectRequirements = new AspectRequirements();

        for (rule in rules) {
            stateRequirements.absorb(rule.listStateAspectRequirements());
            playerRequirements.absorb(rule.listPlayerAspectRequirements());
            boardRequirements.absorb(rule.listBoardAspectRequirements());
        }

        // Populate the game state with aspects, players and nodes
        createAspects(stateRequirements, allocator, state.aspects);
        for (ike in 0...cfg.playerGenes.length) {
            var genome:String = cfg.playerGenes[ike];
            var head:BoardNode = cfg.playerHeads[ike];
            state.players.push(makePlayer(genome, head, playerRequirements, allocator));
        }

        // Populate each node in the graph with aspects
        for (node in cfg.playerHeads[0].getGraph()) createAspects(boardRequirements, allocator, node.value);

        for (rule in rules) rule.init(state);

        return state;
    }

    inline function makePlayer(genome:String, head:BoardNode, requirements:AspectRequirements, allocator:HistoryAllocator):PlayerState {
        var playerState:PlayerState = new PlayerState();
        playerState.genome = genome;
        playerState.head = head;
        createAspects(requirements, allocator, playerState.aspects);
        return playerState;
    }

    inline function createAspects(requirements:AspectRequirements, allocator:HistoryAllocator, aspects:Aspects = null):Aspects {
        if (aspects == null) aspects = new Aspects();
        for (key in requirements.keys()) if (!aspects.exists(key)) aspects.set(key, Type.createInstance(requirements.get(key), [allocator]));
        return aspects;
    }
}
