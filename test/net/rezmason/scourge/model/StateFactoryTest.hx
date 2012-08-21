package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.Aspect;
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

        // make board config and generate board
        var boardCfg:BoardConfig = new BoardConfig();
        boardCfg.numPlayers = 2;
        boardCfg.circular = false;
        var boardFactory:BoardFactory = new BoardFactory();
        var boardData:BoardData = boardFactory.makeBoard(boardCfg, history);

        // Ugly. Change.
        var heads:Array<Int> = boardData.heads;
        var nodes:Array<BoardNode> = boardData.nodes;

        var boardBefore:String = BoardUtils.spitGrid(nodes[0], history, false);

        // make state config and generate state
        var factory:StateFactory = new StateFactory();
        var stateCfg:StateConfig = new StateConfig();
        stateCfg.playerHeads = heads;
        stateCfg.numPlayers = 2;
        stateCfg.nodes = nodes;
        stateCfg.rules = [null, new TestRule()];
        var state:State = factory.makeState(stateCfg, history);

        Assert.areEqual(stateCfg.numPlayers, state.players.length);

        // Make sure there's the right aspects on the state
        var testAspect:Aspect = state.aspects.get(TestAspect.id);
        Assert.isNotNull(testAspect);
        Assert.isTrue(Std.is(testAspect, TestAspect));
        Assert.isNotNull(history.get(cast(testAspect, TestAspect).value));

        // Make sure there's the right aspects on each player
        for (ike in 0...state.players.length) {
            var player:PlayerState = state.players[ike];
            Assert.areEqual(player.head, heads[ike]);
            testAspect = player.aspects.get(TestAspect.id);
            Assert.isNotNull(testAspect);
            Assert.isTrue(Std.is(testAspect, TestAspect));
            Assert.isNotNull(history.get(cast(testAspect, TestAspect).value));
        }

        for (node in state.nodes) {
            testAspect = node.value.get(TestAspect.id);
            Assert.isNotNull(testAspect);
            Assert.isTrue(Std.is(testAspect, TestAspect));
            Assert.isNotNull(history.get(cast(testAspect, TestAspect).value));

            Assert.isNotNull(node.value.get(OwnershipAspect.id));
            Assert.isTrue(Std.is(node.value.get(OwnershipAspect.id), OwnershipAspect));
        }

        // Make sure the board renders the same way
        Assert.areEqual(boardBefore, BoardUtils.spitGrid(state.nodes[0], history, false));
    }
}
