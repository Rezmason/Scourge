package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.aspects.PieceAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.evaluators.TestEvaluator;
import net.rezmason.scourge.model.rules.BuildBoardRule;
import net.rezmason.scourge.model.rules.DecayRule;
import net.rezmason.scourge.model.rules.DraftPlayersRule;
import net.rezmason.scourge.model.rules.DropPieceRule;
import net.rezmason.scourge.model.rules.EatCellsRule;
import net.rezmason.scourge.model.rules.TestPieceRule;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class PieceRulesTest extends RuleTest
{
	@Before
    public function setup():Void {
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace("tick " + time);
    }

	@Test
	public function placePieceRuleTest1():Void {

        var pieceSize:Int = 4;

        // An L/J block has nine neighbor cells.
        // Reflection allowed   rotation allowed    option count
        // N                    N                   9
        // Y                    N                   18
        // N                    Y                   36
        // Y                    Y                   72

        var testPieceCfg:TestPieceConfig = {
            pieceID:Pieces.getPieceIdBySizeAndIndex(pieceSize, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {overlapSelf:false, allowFlipping:true, allowRotating:true};
        var dropRule:DropPieceRule = new DropPieceRule(dropConfig);
        state = makeState(TestBoards.emptyPetri, 1, [testPieceRule, dropRule]);

        dropRule.update();
        var options:Array<DropPieceOption> = cast dropRule.options;

        Assert.areEqual(72, options.length);

        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        //trace(BoardUtils.spitBoard(state));
        dropRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1 + pieceSize, numCells); // 5 cells for player 0
	}
}
