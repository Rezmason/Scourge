package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.aspects.Aspect;
import net.rezmason.scourge.model.aspects.TestAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.rules.TestRule;

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

        var history:History<Int> = new History<Int>();
        var historyArray:Array<Int> = history.array;

        var genes:Array<String> = ["a", "b"];

        // make board config and generate board
        var boardCfg:BoardConfig = new BoardConfig();
        boardCfg.numPlayers = genes.length;
        boardCfg.circular = false;
        var boardFactory:BoardFactory = new BoardFactory();
        var heads:Array<BoardNode> = boardFactory.makeBoard(boardCfg, history);

        var boardBefore:String = spitGrid(heads[0], historyArray, false);

        // make state config and generate state
        var factory:StateFactory = new StateFactory();
        var stateCfg:StateConfig = new StateConfig();
        for (head in heads) stateCfg.playerHeads.push(head);
        for (gene in genes) stateCfg.playerGenes.push(gene);
        stateCfg.rules.push(null);
        stateCfg.rules.push(new TestRule());
        var state:State = factory.makeState(stateCfg, history);

        Assert.areEqual(stateCfg.playerGenes.length, state.players.length);

        // Make sure there's the right aspects on the state
        Assert.isNotNull(state.aspects.get(TestAspect.id));
        Assert.isTrue(Std.is(state.aspects.get(TestAspect.id), TestAspect));

        // Make sure there's the right aspects on each players
        for (ike in 0...state.players.length) {
            var player:PlayerState = state.players[ike];
            Assert.areEqual(player.genome, genes[ike]);
            Assert.areEqual(player.head, heads[ike]);
            Assert.isNotNull(player.aspects.get(TestAspect.id));
            Assert.isTrue(Std.is(player.aspects.get(TestAspect.id), TestAspect));
        }

        for (node in state.players[0].head.getGraph()) {
            Assert.isNotNull(node.value.get(TestAspect.id));
            Assert.isTrue(Std.is(node.value.get(TestAspect.id), TestAspect));

            Assert.isNotNull(node.value.get(OwnershipAspect.id));
            Assert.isTrue(Std.is(node.value.get(OwnershipAspect.id), OwnershipAspect));
        }

        // Make sure the board renders the same way
        Assert.areEqual(boardBefore, spitGrid(state.players[0].head, historyArray, false));

        history.wipe();

        for (ike in historyArray) Assert.isNull(ike);
    }

    private function spitGrid(head:BoardNode, historyArray:Array<Int>, addSpaces:Bool = true):String {
        var str:String = "";

        var grid:BoardNode = head.run(Gr.nw).run(Gr.w).run(Gr.n);

        for (row in grid.walk(Gr.s)) {
            str += "\n";
            for (column in row.walk(Gr.e)) {
                str += nodeToString(column, historyArray);
            }
        }

        if (addSpaces) str = ADD_SPACES.replace(str, "$1 ");

        return str;
    }

    private function nodeToString(node:BoardNode, historyArray:Array<Int>):String {
        var ownerAspect:OwnershipAspect = getOwner(node);
        if (historyArray[ownerAspect.occupier] > -1) return Std.string(historyArray[ownerAspect.occupier]);
        if (historyArray[ownerAspect.isFilled] == 1) return "X";

        return " ";
    }

    private function getOwner(node:BoardNode):OwnershipAspect {
        return cast node.value.get(OwnershipAspect.id);
    }
}
