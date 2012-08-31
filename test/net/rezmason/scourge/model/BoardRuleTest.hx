package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.Aspect;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.rules.BuildBoardRule;
import net.rezmason.scourge.model.rules.DraftPlayersRule;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class BoardRuleTest {

    var history:StateHistory;
    var time:Float;

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
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace(time);
    }

    @Test
    public function configTest1():Void {

        var boardCfg:BoardConfig = new BoardConfig();
        boardCfg.circular = false;
        var buildBoardRule:BuildBoardRule = new BuildBoardRule(boardCfg);

        var playerCfg:PlayerConfig = new PlayerConfig();
        playerCfg.numPlayers = 4;
        var draftPlayersRule:DraftPlayersRule = new DraftPlayersRule(playerCfg);

        var state:State = makeState([draftPlayersRule, buildBoardRule]);

        var occupier_:AspectPtr = state.nodeAspectLookup[OwnershipAspect.OCCUPIER.id];
        var head_:AspectPtr = state.playerAspectLookup[BodyAspect.HEAD.id];

        for (player in state.players) {
            Assert.isNotNull(player.at(head_));
            Assert.areNotEqual(-1, player.at(head_));
        }

        for (node in state.nodes) {
            Assert.isNotNull(node);
            Assert.isNotNull(history.get(node.value.at(occupier_)));
        }

        #if VISUAL_TEST
            trace("VISUAL ASSERTION: Should appear to be four integers, equally spaced and equally distant from the edges of a box");
            trace(BoardUtils.spitBoard(state));
        #else
            Assert.areEqual(TestBoards.emptySquareFourPlayerSkirmish, BoardUtils.spitBoard(state, false));
        #end

        var currentPlayer_:AspectPtr = state.stateAspectLookup[PlyAspect.CURRENT_PLAYER.id];
        var currentPlayer:Int = history.get(state.aspects.at(currentPlayer_));

        var playerHead:BoardNode = state.nodes[history.get(state.players[currentPlayer].at(head_))];

        for (neighbor in playerHead.neighbors) {
            Assert.isNotNull(neighbor);
            Assert.areEqual(-1, history.get(neighbor.value.at(occupier_)));
            history.set(neighbor.value.at(occupier_), 0);
        }

        Assert.areEqual(0, history.get(playerHead.nw().value.at(occupier_)));
        Assert.areEqual(0, history.get(playerHead.n( ).value.at(occupier_)));
        Assert.areEqual(0, history.get(playerHead.ne().value.at(occupier_)));
        Assert.areEqual(0, history.get(playerHead.e( ).value.at(occupier_)));
        Assert.areEqual(0, history.get(playerHead.se().value.at(occupier_)));
        Assert.areEqual(0, history.get(playerHead.s( ).value.at(occupier_)));
        Assert.areEqual(0, history.get(playerHead.sw().value.at(occupier_)));
        Assert.areEqual(0, history.get(playerHead.w( ).value.at(occupier_)));
    }

    @Test
    public function configTest2():Void {

        var boardCfg:BoardConfig = new BoardConfig();
        boardCfg.circular = true;
        var buildBoardRule:BuildBoardRule = new BuildBoardRule(boardCfg);

        var playerCfg:PlayerConfig = new PlayerConfig();
        playerCfg.numPlayers = 1;
        var draftPlayersRule:DraftPlayersRule = new DraftPlayersRule(playerCfg);

        var state:State = makeState([draftPlayersRule, buildBoardRule]);

        #if VISUAL_TEST
            trace("VISUAL ASSERTION: Should appear to be an integer in the center of a perfect circle, which should fit neatly in a box");
            trace(BoardUtils.spitBoard(state));
        #else
            Assert.areEqual(TestBoards.emptyPetri, BoardUtils.spitBoard(state, false));
        #end
    }

    @Test
    public function configTest3():Void {

        var boardCfg:BoardConfig = new BoardConfig();
        boardCfg.circular = false;
        boardCfg.initGrid = TestBoards.spiral;
        var buildBoardRule:BuildBoardRule = new BuildBoardRule(boardCfg);

        var playerCfg:PlayerConfig = new PlayerConfig();

        playerCfg.numPlayers = 4;
        var draftPlayersRule:DraftPlayersRule = new DraftPlayersRule(playerCfg);

        var state:State = makeState([draftPlayersRule, buildBoardRule]);

        #if VISUAL_TEST
            trace("VISUAL ASSERTION: Should appear to be a four-player board with a spiral interior");
            trace(BoardUtils.spitBoard(state));
        #end

        Assert.areEqual(TestBoards.spiral, BoardUtils.spitBoard(state, false));

        //trace(history.dump());
    }

    private function makeState(rules:Array<Rule>):State {
        history.wipe();
        var factory:StateFactory = new StateFactory();
        var stateCfg:StateConfig = new StateConfig();
        stateCfg.rules = rules;
        return factory.makeState(stateCfg, history);
    }
}
