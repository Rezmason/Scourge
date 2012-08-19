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

        var boardBefore:String = BoardUtils.spitGrid(heads[0], historyArray, false);

        // make state config and generate state
        var factory:StateFactory = new StateFactory();
        var stateCfg:StateConfig = new StateConfig();
        stateCfg.playerHeads = heads;
        stateCfg.playerGenes = genes;
        stateCfg.rules = [null, new TestRule()];
        var state:State = factory.makeState(stateCfg, history);

        Assert.areEqual(stateCfg.playerGenes.length, state.players.length);

        // Make sure there's the right aspects on the state
        var testAspect:Aspect = state.aspects.get(TestAspect.id);
        Assert.isNotNull(testAspect);
        Assert.isTrue(Std.is(testAspect, TestAspect));
        Assert.isNotNull(historyArray[cast(testAspect, TestAspect).value]);

        // Make sure there's the right aspects on each player
        for (ike in 0...state.players.length) {
            var player:PlayerState = state.players[ike];
            Assert.areEqual(player.genome, genes[ike]);
            Assert.areEqual(player.head, heads[ike]);
            testAspect = player.aspects.get(TestAspect.id);
            Assert.isNotNull(testAspect);
            Assert.isTrue(Std.is(testAspect, TestAspect));
            Assert.isNotNull(historyArray[cast(testAspect, TestAspect).value]);
        }

        for (node in state.players[0].head.getGraph()) {
            testAspect = node.value.get(TestAspect.id);
            Assert.isNotNull(testAspect);
            Assert.isTrue(Std.is(testAspect, TestAspect));
            Assert.isNotNull(historyArray[cast(testAspect, TestAspect).value]);

            Assert.isNotNull(node.value.get(OwnershipAspect.id));
            Assert.isTrue(Std.is(node.value.get(OwnershipAspect.id), OwnershipAspect));
        }

        // Make sure the board renders the same way
        Assert.areEqual(boardBefore, BoardUtils.spitGrid(state.players[0].head, historyArray, false));

        history.wipe();

        // Make sure the aspects were nulled on the state
        Assert.isNull(historyArray[cast(state.aspects.get(TestAspect.id), TestAspect).value]);

        // Make sure the aspects were nulled on each player
        for (ike in 0...state.players.length) {
            var player:PlayerState = state.players[ike];
            Assert.isNull(historyArray[cast(player.aspects.get(TestAspect.id), TestAspect).value]);
        }

        // Make sure the aspects were nulled on each node
        for (node in state.players[0].head.getGraph()) {
            Assert.isNull(historyArray[cast(node.value.get(TestAspect.id), TestAspect).value]);
        }
    }
}
