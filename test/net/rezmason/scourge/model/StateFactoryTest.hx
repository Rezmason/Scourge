package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.aspects.Aspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using net.rezmason.scourge.model.GridUtils;

class StateFactoryTest {

    private static var ADD_SPACES:EReg = ~/([^\n\t])/g;

    @Before
    public function setup():Void {

    }

    @After
    public function tearDown():Void {

    }

    @Test
    public function configTest1():Void {

        var genes:Array<String> = ["a", "b"];

        // make board config and generate board
        var boardCfg:BoardConfig = new BoardConfig();
        boardCfg.numPlayers = genes.length;
        boardCfg.circular = false;
        var boardFactory:BoardFactory = new BoardFactory();
        var heads:Array<BoardNode> = boardFactory.makeBoard(boardCfg);

        var boardBefore:String = spitGrid(heads[0], false);

        // make state config and generate state
        var factory:StateFactory = new StateFactory();
        var stateCfg:StateConfig = new StateConfig();
        for (head in heads) stateCfg.playerHeads.push(head);
        for (gene in genes) stateCfg.playerGenes.push(gene);
        stateCfg.rules.push(null); // TODO: Add rules
        var state:State = factory.makeState(stateCfg);

        Assert.areEqual(stateCfg.playerGenes.length, state.players.length);

        // Make sure there's the right aspects on the state
        for (aspect in state.aspects) {
            // TODO: Check that rule aspect requirements appear
        }

        // Make sure there's the right aspects on each players
        for (ike in 0...state.players.length) {
            var player:PlayerState = state.players[ike];
            Assert.areEqual(player.genome, genes[ike]);
            Assert.areEqual(player.head, heads[ike]);
            for (aspect in player.aspects) {
                // TODO: Check that rule aspect requirements appear
            }
        }

        for (node in state.players[0].head.getGraph()) {
            for (aspect in node.value) {
                // TODO: Check that rule aspect requirements appear
            }
        }

        // Make sure the board renders the same way
        Assert.areEqual(boardBefore, spitGrid(state.players[0].head, false));
    }

    private function spitGrid(head:BoardNode, addSpaces:Bool = true):String {
        var str:String = "";

        var grid:BoardNode = head.run(Gr.nw).run(Gr.w).run(Gr.n);

        for (row in grid.walk(Gr.s)) {
            str += "\n";
            for (column in row.walk(Gr.e)) {
                str += nodeToString(column);
            }
        }

        if (addSpaces) str = ADD_SPACES.replace(str, "$1 ");

        return str;
    }

    private function nodeToString(node:BoardNode):String {
        var ownerAspect:OwnershipAspect = getOwner(node);
        if (ownerAspect.occupier > -1) return Std.string(ownerAspect.occupier);
        if (ownerAspect.isFilled == 1) return "X";

        return " ";
    }

    private function getOwner(node:BoardNode):OwnershipAspect {
        return cast node.value.get(OwnershipAspect.id);
    }
}
