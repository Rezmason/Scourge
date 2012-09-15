package net.rezmason.scourge.model;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.Aspect;
import net.rezmason.scourge.model.aspects.PlyAspect;

using Lambda;
using Std;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.ArrayUtils;
using net.rezmason.utils.Pointers;

class StateFactory {
    public function new():Void {

    }

    public function makeState(rules:Array<Rule>, history:StateHistory):State {
        if (rules == null) return null;

        var state:State = new State();

        while (rules.has(null)) rules.remove(null);

        // Create and populate the aspect requirement lists
        var stateRequirements:AspectRequirements = new AspectRequirements();
        var playerRequirements:AspectRequirements = new AspectRequirements();
        var nodeRequirements:AspectRequirements = new AspectRequirements();

        for (rule in rules) {
            stateRequirements.absorb(rule.stateAspectRequirements);
            playerRequirements.absorb(rule.playerAspectRequirements);
            nodeRequirements.absorb(rule.nodeAspectRequirements);
        }

        // TEMPORARY
        if (!stateRequirements.has(PlyAspect.CURRENT_PLAYER)) stateRequirements.push(PlyAspect.CURRENT_PLAYER);

        // Populate state with aspect templates and lookups
        state.stateAspectLookup = [];
        state.playerAspectLookup = [];
        state.nodeAspectLookup = [];

        state.stateAspectTemplate = [];
        state.playerAspectTemplate = [];
        state.nodeAspectTemplate = [];

        bakeAspectSet(stateRequirements, state.stateAspectLookup, state.stateAspectTemplate);
        bakeAspectSet(playerRequirements, state.playerAspectLookup, state.playerAspectTemplate);
        bakeAspectSet(nodeRequirements, state.nodeAspectLookup, state.nodeAspectTemplate);

        // Populate the game state with aspects, players and nodes
        state.aspects = createAspectSet(state.stateAspectTemplate, history);

        state.players = [];
        state.nodes = [];

        for (rule in rules) rule.init(state);

        return state;
    }

    function bakeAspectSet(requirements:AspectRequirements, lookup:AspectLookup, template:AspectSet):Void {
        for (ike in 0...requirements.length) {
            var prop:AspectProperty = requirements[ike];
            lookup[prop.id] = ike.pointerArithmetic();
            template[ike] = prop.initialValue;
        }
    }

    inline function createAspectSet(template:AspectSet, history:StateHistory):AspectSet {
        var aspects:AspectSet = new AspectSet();
        for (val in template) {
            //aspects.push(history.alloc(val)); // H
            aspects.push(val);
        }
        return aspects;
    }
}
