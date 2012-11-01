package net.rezmason.scourge.model.rules;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.BiteAspect;

using Lambda;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

typedef BiteConfig = {
    var minReach:Int;
    var maxReach:Int;
    var maxSizeReference:Int;
    var baseReachOnThickness:Bool;
    var omnidirectional:Bool;
    var biteThroughCavities:Bool;
    var biteHeads:Bool;
    var orthoOnly:Bool;
    var startingBites:Int;
}

typedef BiteOption = {>Option,
    var targetNode:Int;
    var bitNodes:Array<Int>;
    var thickness:Int;
    var duplicate:Bool;
}

class BiteRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(BodyAspect.NODE_ID) var nodeID_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BiteAspect.NUM_BITES) var numBites_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.HEAD) var head_;
    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;
    @state(PlyAspect.CURRENT_PLAYER) var currentPlayer_;

    private var cfg:BiteConfig;
    private var biteOptions:Array<BiteOption>;

    public function new(cfg:BiteConfig):Void {
        super();
        this.cfg = cfg;
    }

    override public function init():Void {
        for (player in state.players) player.mod(numBites_, cfg.startingBites);
    }

    override public function update():Void {

        biteOptions = [];

        // get current player head
        var currentPlayer:Int = state.aspects.at(currentPlayer_);

        var headIDs:Array<Int> = [];
        for (player in state.players) headIDs.push(player.at(head_));

        if (state.players[currentPlayer].at(numBites_) > 0) {
            var totalArea:Int = state.players[currentPlayer].at(totalArea_);
            var bodyNode:BoardNode = state.nodes[state.players[currentPlayer].at(bodyFirst_)];
            var body:Array<BoardNode> = bodyNode.boardListToArray(state.nodes, bodyNext_);
            var frontNodes:Array<BoardNode> = body.filter(callback(isFront, headIDs)).array();

            // Grab the valid bites from immediate neighbors

            var newOptions:Array<BiteOption> = [];
            for (node in frontNodes) {
                for (neighbor in neighborsFor(node)) {
                    if (isValidEnemy(headIDs, currentPlayer, neighbor)) {
                        var option:BiteOption = makeOption(node.value.at(nodeID_), [neighbor.value.at(nodeID_)]);
                        if (!cfg.omnidirectional && cfg.baseReachOnThickness) {
                            // The baseReachOnThickness config param uses this data to determine how far to extend a bite
                            var backwards:Int = (node.neighbors.indexOf(neighbor) + 4) % 8;
                            var depth:Int = 0;
                            for (innerNode in node.walk(backwards)) {
                                if (innerNode.value.at(occupier_) == currentPlayer) depth++;
                                else break;
                            }
                            option.thickness = depth;
                        }
                        newOptions.push(option);
                    }
                }
            }
            for (ike in 0...newOptions.length) newOptions[ike].optionID = ike;
            biteOptions = newOptions.copy();

            // Extend the existing valid bites

            var reachItr:Int = 1;
            var growthPercent:Float = Math.min(1, totalArea / cfg.maxSizeReference); // The "size calculation" for players
            var reach:Int = Std.int(cfg.minReach + growthPercent * (cfg.maxReach - cfg.minReach));
            if (cfg.baseReachOnThickness) reach = cfg.maxReach;

            // We find options by taking existing options and extending them until there's nothing left to extend
            while (reachItr < reach && newOptions.length > 0) {
                var oldOptions:Array<BiteOption> = newOptions;
                newOptions = [];

                for (option in oldOptions) {
                    if (cfg.omnidirectional) {
                        // Omnidirectional options are squiggly
                        for (bitNodeID in option.bitNodes) {
                            var bitNode:BoardNode = state.nodes[bitNodeID];
                            for (neighbor in neighborsFor(bitNode)) {
                                if (isValidEnemy(headIDs, currentPlayer, neighbor) && !option.bitNodes.has(neighbor.value.at(nodeID_))) {
                                    newOptions.push(makeOption(option.targetNode, option.bitNodes.concat([neighbor.value.at(nodeID_)]), option));
                                }
                            }
                        }
                    } else if (!cfg.baseReachOnThickness || option.bitNodes.length < option.thickness) {
                        // Straight options are a little easier to generate
                        var firstBitNode:BoardNode = state.nodes[option.bitNodes[0]];
                        var lastBitNode:BoardNode = state.nodes[option.bitNodes[option.bitNodes.length - 1]];
                        var direction:Int = state.nodes[option.targetNode].neighbors.indexOf(firstBitNode);
                        var neighbor:BoardNode = lastBitNode.neighbors[direction];
                        if (isValidEnemy(headIDs, currentPlayer, neighbor)) {
                            var nextOption:BiteOption = makeOption(option.targetNode, option.bitNodes.concat([neighbor.value.at(nodeID_)]), option);
                            nextOption.thickness = option.thickness;
                            newOptions.push(nextOption);
                        }
                    }
                }

                for (ike in 0...newOptions.length) newOptions[ike].optionID = ike + biteOptions.length;
                biteOptions = biteOptions.concat(newOptions);

                reachItr++;
            }
        }

        // We find all options that represent the same action and mark the duplicates
        // (This helps AI players)
        for (ike in 0...biteOptions.length) {
            var biteOption:BiteOption = biteOptions[ike];
            if (biteOption.duplicate) continue;
            for (jen in ike + 1...biteOptions.length) {
                if (biteOptions[jen].duplicate) continue;
                biteOptions[jen].duplicate = optionsAreEqual(biteOption, biteOptions[jen]);
            }
        }

        //trace("\n" + biteOptions.join("\n"));

        options = cast biteOptions;
    }

    override public function chooseOption(choice:Int):Void {
        super.chooseOption(choice);

        var option:BiteOption = cast options[choice];

        if (option.targetNode != Aspect.NULL) {

            // Grab data from the option

            var node:BoardNode = state.nodes[option.targetNode];
            var currentPlayer:Int = state.aspects.at(currentPlayer_);

            var maxFreshness:Int = state.aspects.at(maxFreshness_) + 1;
            var numBites:Int = state.players[currentPlayer].at(numBites_) - 1;

            // Find the cells removed from each player

            var bitNodesByPlayer:Array<Array<BoardNode>> = [];
            for (ike in 0...state.players.length) bitNodesByPlayer.push([]);

            for (bitNodeID in option.bitNodes) {
                var bitNode:BoardNode = state.nodes[bitNodeID];
                bitNodesByPlayer[bitNode.value.at(occupier_)].push(bitNode);
            }

            // Remove the appropriate cells from each player

            for (ike in 0...state.players.length) {
                var player:AspectSet = state.players[ike];
                var bitNodes:Array<BoardNode> = bitNodesByPlayer[ike];
                var bodyFirst:Int = player.at(bodyFirst_);

                for (node in bitNodes) bodyFirst = killCell(node, maxFreshness++, bodyFirst);

                player.mod(bodyFirst_, bodyFirst);
            }

            state.aspects.mod(maxFreshness_, maxFreshness);
            state.players[currentPlayer].mod(numBites_, numBites);
        }
    }

    // "front" as in "battle front". Areas where the current player touches other players
    inline function isFront(headIDs:Array<Int>, node:BoardNode):Bool {
        return neighborsFor(node).exists(callback(isValidEnemy, headIDs, node.value.at(occupier_)));
    }

    // Depending on the config, enemy nodes of different kinds can be bitten
    inline function isValidEnemy(headIDs:Array<Int>, allegiance:Int, node:BoardNode):Bool {
        var val:Bool = true;
        if (node.value.at(occupier_) == allegiance) val = false; // Can't be the current player
        else if (node.value.at(occupier_) == Aspect.NULL) val = false; // Can't be the current player
        else if (!cfg.biteThroughCavities && node.value.at(isFilled_) == Aspect.FALSE) val = false; // Must be filled, or must allow biting through a cavity
        else if (!cfg.biteHeads && headIDs.has(node.value.at(nodeID_))) val = false;

        return val;
    }

    inline function makeOption(targetNodeID:Int, bitNodes:Array<Int>, relatedOption:BiteOption = null):BiteOption {
        var option:BiteOption = {
            optionID:-1,
            targetNode:targetNodeID,
            bitNodes:bitNodes,
            relatedOptionID:(relatedOption == null ? null : relatedOption.optionID),
            thickness:1,
            duplicate:false,
        };

        return option;
    }

    // compares the bit nodes of two options; if they're the same, then the options have the same consequence
    inline function optionsAreEqual(option1:BiteOption, option2:BiteOption):Bool {
        var val:Bool = true;
        if (option1.bitNodes.length != option2.bitNodes.length) val = false;
        else for (bitNode in option1.bitNodes) if (!option2.bitNodes.has(bitNode)) { val = false; break; }
        return val;
    }

    inline function killCell(node:BoardNode, freshness:Int, firstIndex:Int):Int {
        if (node.value.at(isFilled_) == Aspect.TRUE) {
            var nextNode:BoardNode = node.removeNode(state.nodes, bodyNext_, bodyPrev_);
            if (firstIndex == node.value.at(nodeID_)) firstIndex = nextNode == null ? Aspect.NULL : nextNode.value.at(nodeID_);
            node.value.mod(isFilled_, Aspect.FALSE);
        }

        node.value.mod(occupier_, Aspect.NULL);
        node.value.mod(freshness_, freshness);

        return firstIndex;
    }

    inline function neighborsFor(node:BoardNode):Array<BoardNode> {
        return cfg.orthoOnly ? node.orthoNeighbors() : node.allNeighbors();
    }
}
