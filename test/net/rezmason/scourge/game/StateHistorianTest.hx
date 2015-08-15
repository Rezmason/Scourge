package net.rezmason.scourge.game;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.state.State;
import net.rezmason.praxis.state.StateHistorian;
import net.rezmason.praxis.state.StatePlanner;
import net.rezmason.scourge.game.meta.FreshnessAspect;
import net.rezmason.scourge.game.body.EatCellsRule;
import net.rezmason.scourge.game.build.BuildBoardRule;
import net.rezmason.scourge.game.build.BuildPlayersRule;
import net.rezmason.scourge.game.build.BuildGlobalRule;
import net.rezmason.scourge.game.build.PetriBoardFactory;
import net.rezmason.scourge.game.piece.PickPieceRule;
import net.rezmason.utils.openfl.Resource;

using net.rezmason.utils.Pointers;
using net.rezmason.scourge.game.BoardUtils;
using net.rezmason.praxis.state.StatePlan;

class StateHistorianTest {

    #if TIME_TESTS
    var time:Float;

    @Before
    public function setup():Void {
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace('tick $time');
    }
    #end


    @Test
    public function transferAndCommitTest():Void {

        var historian:StateHistorian = new StateHistorian();

        var history:StateHistory = historian.history;
        var historyState:State = historian.historyState;
        var state:State = historian.state;
        
        var config = {
            firstPlayer:0,
            numPlayers:2,
            cells:PetriBoardFactory.create(2, false, TestBoards.twoPlayerGrab),

            recursive:false,
            eatHeads:true,
            takeBodiesFromHeads:false,

            pieceTableIDs:[0, 1, 2, 3, 4],
            allowFlipping:true,
            allowRotating:true,
            allowAll:false,
            hatSize:1,
            pieces:new Pieces(Resource.getString('tables/pieces.json.txt'))
        }

        var buildStateRule:BuildGlobalRule = new BuildGlobalRule(cast config);
        var buildPlayersRule:BuildPlayersRule = new BuildPlayersRule(cast config);
        var buildBoardRule:BuildBoardRule = new BuildBoardRule(cast config);
        var eatRule:EatCellsRule = new EatCellsRule(cast config);
        var pickPieceRule:PickPieceRule = new PickPieceRule(cast config);

        var rules:Array<Rule> = [buildStateRule, buildPlayersRule, buildBoardRule, eatRule, pickPieceRule];
        var plan:StatePlan = new StatePlanner().planState(state, rules);
        for (rule in rules) rule.prime(state, plan, history, historyState);
        var freshness_:AspectPtr = plan.onNode(FreshnessAspect.FRESHNESS);


        var boards:Array<String> = [];
        var times:Array<Int> = [];
        var extras:Array<String> = [];

        function pushChange():Void {
            boards.push(state.spitBoard(plan));
            extras.push(Std.string(state.extras));
            historian.write();
            times.push(history.commit());
        }

        pushChange();

        // Pick a few pieces
        for (ike in 0...10) {
            pickPieceRule.update();
            pickPieceRule.chooseMove();
        }

        // Freshen and eat body

        state.grabXY(7, 7).value[freshness_] = 1;
        state.grabXY(9, 7).value[freshness_] = 1;
        eatRule.chooseMove();

        pushChange();

        // Freshen and eat head
        state.grabXY(12, 6).value[freshness_] = 1;
        eatRule.chooseMove();

        pushChange();

        // No change!

        pushChange();

        while (times.length > 0) {
            history.revert(times.pop());
            historian.read();
            Assert.areEqual(boards.pop(), state.spitBoard(plan));
            Assert.areEqual(extras.pop(), Std.string(state.extras));
        }
    }
}
