package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.Aspect;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.rules.BuildBoardRule;

using net.rezmason.scourge.model.GridUtils;

class BoardRuleTest {

    var history:StateHistory;

    @BeforeClass
    public function beforeClass():Void {
        history = new StateHistory();
    }

    @AfterClass
    public function afterClass():Void {
        history.wipe();
        history = null;
    }

    @Before
    public function setup():Void {

    }

    @After
    public function tearDown():Void {

    }

    @Test
    public function configTest1():Void {

        var cfg:BoardConfig = new BoardConfig();
        cfg.circular = false;

        var buildBoardRule = new BuildBoardRule(cfg);
        var state:State = makeState(4, [buildBoardRule]);

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];

        Assert.isNotNull(occupier_);
        Assert.isNotNull(head_);

        for (player in state.players) {
            Assert.isNotNull(player[head_]);
            Assert.areNotEqual(-1, player[head_]);
        }

        for (node in state.nodes) {
            Assert.isNotNull(node);
            Assert.isNotNull(history.get(node.value[occupier_]));
        }

        #if VISUAL_TEST
            trace("VISUAL ASSERTION: Should appear to be four integers, equally spaced and equally distant from the edges of a box");
            trace(BoardUtils.spitBoard(state));
        #else
            Assert.areEqual(TestBoards.emptySquareFourPlayerSkirmish, BoardUtils.spitBoard(state, false));
        #end

        var playerHead:BoardNode = state.nodes[history.get(state.players[0][head_])];

        for (neighbor in playerHead.neighbors) {
            Assert.isNotNull(neighbor);
            Assert.areEqual(-1, history.get(neighbor.value[occupier_]));
            history.set(neighbor.value[occupier_], 0);
        }

        Assert.areEqual(0, history.get(playerHead.nw().value[occupier_]));
        Assert.areEqual(0, history.get(playerHead.n().value[occupier_]));
        Assert.areEqual(0, history.get(playerHead.ne().value[occupier_]));
        Assert.areEqual(0, history.get(playerHead.e().value[occupier_]));
        Assert.areEqual(0, history.get(playerHead.se().value[occupier_]));
        Assert.areEqual(0, history.get(playerHead.s().value[occupier_]));
        Assert.areEqual(0, history.get(playerHead.sw().value[occupier_]));
        Assert.areEqual(0, history.get(playerHead.w().value[occupier_]));
    }

    @Test
    public function configTest2():Void {

        var cfg:BoardConfig = new BoardConfig();
        cfg.circular = true;

        var buildBoardRule = new BuildBoardRule(cfg);

        var state:State = makeState(1, [buildBoardRule]);

        #if VISUAL_TEST
            trace("VISUAL ASSERTION: Should appear to be an integer in the center of a perfect circle, which should fit neatly in a box");
            trace(BoardUtils.spitBoard(state));
        #else
            Assert.areEqual(TestBoards.emptyPetri, BoardUtils.spitBoard(state, false));
        #end
    }

    @Test
    public function configTest3():Void {

        var cfg:BoardConfig = new BoardConfig();
        cfg.initGrid = TestBoards.spiral;

        var buildBoardRule = new BuildBoardRule(cfg);

        var state:State = makeState(4, [buildBoardRule]);

        #if VISUAL_TEST
            trace("VISUAL ASSERTION: Should appear to be a four-player board with a spiral interior");
            trace(BoardUtils.spitBoard(state));
        #end

        Assert.areEqual(TestBoards.spiral, BoardUtils.spitBoard(state, false));

        //trace(history.dump());
    }

    private function makeState(numPlayers:Int, rules:Array<Rule>):State {
        history.wipe();
        var factory:StateFactory = new StateFactory();
        var stateCfg:StateConfig = new StateConfig();
        stateCfg.numPlayers = numPlayers;
        stateCfg.rules = rules;
        return factory.makeState(stateCfg, history);
    }
}
