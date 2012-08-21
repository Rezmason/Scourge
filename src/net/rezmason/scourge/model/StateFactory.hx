package net.rezmason.scourge.model;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.Aspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;
using Std;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.IntHashUtils;

class StateFactory {
    public function new():Void {

    }

    public function makeState(cfg:StateConfig, history:History<Int>):State {
        if (cfg == null) return null;
        if (cfg.numPlayers < 1) return null;
        if (cfg.playerHeads == null) return null;
        if (cfg.nodes == null) return null;
        if (cfg.rules == null) return null;

        var state:State = new State(history);

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

        // TEMPORARY
        if (!stateRequirements.exists(PlyAspect.id)) stateRequirements.set(PlyAspect.id, PlyAspect);

        // Populate the game state with aspects, players and nodes
        createAspects(stateRequirements, history, state.aspects);
        for (ike in 0...cfg.numPlayers) {
            state.players.push(makePlayer(cfg.playerHeads[ike], playerRequirements, history));
        }

        // Populate each node in the graph with aspects
        for (node in cfg.nodes) createAspects(boardRequirements, history, node.value);
        state.nodes = cfg.nodes.copy();

        for (rule in rules) rule.init(state);

        return state;
    }

    inline function makePlayer(head:Int, requirements:AspectRequirements, history:History<Int>):PlayerState {
        var playerState:PlayerState = new PlayerState();
        playerState.head = head;
        createAspects(requirements, history, playerState.aspects);
        return playerState;
    }

    inline function createAspects(requirements:AspectRequirements, history:History<Int>, aspects:Aspects = null):Aspects {
        if (aspects == null) aspects = new Aspects();
        for (key in requirements.keys()) if (!aspects.exists(key)) aspects.set(key, Type.createInstance(requirements.get(key), [history]));
        return aspects;
    }
}
