package net.rezmason.scourge.model;

import haxe.ds.StringMap;
import haxe.Unserializer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import massive.munit.util.Timer;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.State;
import net.rezmason.ropes.StateHistorian;
import net.rezmason.ropes.StatePlanner;
import net.rezmason.ropes.Aspect;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.model.ScourgeConfigFactory;
import net.rezmason.scourge.model.body.BodyAspect;
import net.rezmason.scourge.model.body.OwnershipAspect;
import net.rezmason.scourge.model.meta.PlyAspect;
import net.rezmason.scourge.model.meta.WinAspect;
import net.rezmason.scourge.model.piece.DropPieceRule;
import net.rezmason.scourge.model.piece.PieceAspect;
import net.rezmason.scourge.model.piece.SwapAspect;
import net.rezmason.scourge.tools.Resource;
import net.rezmason.utils.SafeSerializer;

using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.ropes.GridUtils;
using net.rezmason.ropes.StatePlan;
using net.rezmason.utils.Alphabetizer;
using net.rezmason.utils.Pointers;

class ScourgeConfigFactoryTest
{
    var stateHistorian:StateHistorian;
    var history:StateHistory;
    var state:State;
    var historyState:State;
    var plan:StatePlan;
    var config:ScourgeConfig;
    var combinedRules:StringMap<Rule>;

    var startAction:Rule;
    var biteAction:Rule;
    var swapAction:Rule;
    var quitAction:Rule;
    var dropAction:Rule;

    public function new() {

    }

    @BeforeClass
    public function beforeClass():Void {
        config = new ScourgeConfig();
        stateHistorian = new StateHistorian();

        history = stateHistorian.history;
        state = stateHistorian.state;
        historyState = stateHistorian.historyState;
    }

    @AfterClass
    public function afterClass():Void {
        stateHistorian.reset();

        combinedRules = null;
        config = null;
        stateHistorian = null;
        history = null;
        historyState = null;
        state = null;
        plan = null;
    }

    @Before
    public function setup():Void {
        config = new ScourgeConfig();
        stateHistorian.reset();

        combinedRules = null;
    }

    @Test
    public function configIsSerializable():Void {
        config = Unserializer.run(SafeSerializer.run(config));
    }

    @Test
    public function allActionsRegisteredTest():Void {
        makeState();
        
        for (action in ScourgeConfigFactory.makeActionList(config)) {
            Assert.isNotNull(combinedRules.get(action));
        }
        
        Assert.isNotNull(combinedRules.get(ScourgeConfigFactory.makeStartAction()));
    }

    @Test
    public function startActionTest():Void {
        // decay, cavity, killHeadlessPlayer, oneLivingPlayer, pickPiece

        config.buildParams.numPlayers = 2;
        config.buildParams.initGrid = TestBoards.twoPlayerBullshit;
        makeState();

        VisualAssert.assert('floating zero square, stringy player one with no head', state.spitBoard(plan));

        var num0Cells:Int = ~/([^0])/g.replace(state.spitBoard(plan, false), '').length;
        var num1Cells:Int = ~/([^1])/g.replace(state.spitBoard(plan, false), '').length;

        Assert.areEqual(24, num0Cells);
        Assert.areEqual(32, num1Cells);

        startAction.update();
        startAction.chooseMove();

        VisualAssert.assert('big square player zero with cavity, no player one', state.spitBoard(plan));

        var num0Cells:Int = ~/([^0])/g.replace(state.spitBoard(plan, false), '').length;
        var num1Cells:Int = ~/([^1])/g.replace(state.spitBoard(plan, false), '').length;

        Assert.areEqual(20, num0Cells);
        Assert.areEqual(0, num1Cells);

        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);

        var winner_:AspectPtr = plan.onGlobal(WinAspect.WINNER);
        var currentPlayer_:AspectPtr = plan.onGlobal(PlyAspect.CURRENT_PLAYER);

        Assert.areEqual(36, state.players[0][totalArea_]);
        Assert.areEqual(Aspect.NULL, state.players[1][head_]);
        Assert.areEqual(0, state.global[winner_]);
        Assert.areEqual(0, state.global[currentPlayer_]);
    }

    @Test
    public function biteActionTest():Void {

        // bite, decay, cavity, killHeadlessPlayer, oneLivingPlayer

        config.buildParams.numPlayers = 2;
        config.biteParams.startingBites = 5;
        config.buildParams.initGrid = TestBoards.twoPlayerGrab;
        makeState();

        VisualAssert.assert('two player grab', state.spitBoard(plan));

        var winner_:AspectPtr = plan.onGlobal(WinAspect.WINNER);
        var totalArea_:AspectPtr = plan.onPlayer(BodyAspect.TOTAL_AREA);
        var currentPlayer_:AspectPtr = plan.onGlobal(PlyAspect.CURRENT_PLAYER);

        startAction.update();
        startAction.chooseMove();

        Assert.areEqual(13, state.players[1][totalArea_]);

        VisualAssert.assert('two player grab', state.spitBoard(plan));

        biteAction.update();
        biteAction.chooseMove(4); // bite

        Assert.areEqual(6, state.players[1][totalArea_]);

        VisualAssert.assert('player zero bit off player one\'s leg', state.spitBoard(plan));

        VisualAssert.assert('no difference', state.spitBoard(plan));

        // How about some skipping?
        dropAction.update();
        dropAction.chooseMove(); // skip

        VisualAssert.assert('no difference', state.spitBoard(plan));

        dropAction.update();
        dropAction.chooseMove(); // skip

        biteAction.update();
        biteAction.chooseMove(); // bite head

        Assert.areEqual(0, state.players[1][totalArea_]);

        VisualAssert.assert('player zero bit player one in the head: dead', state.spitBoard(plan));
    }

    @Test
    public function swapActionTest():Void {

        // swapPiece, pickPiece

        config.pieceParams.hatSize = 3;
        config.pieceParams.startingSwaps = 6;
        config.pieceParams.allowFlipping = true;

        makeState();
        startAction.update();
        startAction.chooseMove();

        var numSwaps_:AspectPtr = plan.onPlayer(SwapAspect.NUM_SWAPS);
        var pieceTableID_:AspectPtr = plan.onGlobal(PieceAspect.PIECE_TABLE_ID);

        Assert.areEqual(config.pieceParams.startingSwaps, state.players[0][numSwaps_]);

        var pickedPieces:Array<Null<Int>> = [];

        for (ike in 0...config.pieceParams.startingSwaps) {
            swapAction.update();
            swapAction.chooseMove();

            var piece:Int = state.global[pieceTableID_];

            Assert.areEqual(config.pieceParams.pieceTableIDs[(ike + 1) % config.pieceParams.hatSize], state.global[pieceTableID_]);

            var index:Int = ike % config.pieceParams.hatSize;
            if (pickedPieces[index] == null) pickedPieces[index] = piece;
            else Assert.areEqual(pickedPieces[index], piece);
        }

        Assert.areEqual(0, state.players[0][numSwaps_]);
    }

    @Test
    public function quitActionTest():Void {

        // forfeit, decay, cavity, killHeadlessPlayer, oneLivingPlayer, endTurn, replenish, pickPiece

        config.buildParams.numPlayers = 2;
        makeState();
        startAction.update();
        startAction.chooseMove();

        quitAction.update();
        quitAction.chooseMove(); // player 1 ragequits

        var winner_:AspectPtr = plan.onGlobal(WinAspect.WINNER);

        Assert.areEqual(1, state.global[winner_]);
    }

    @Test
    public function dropActionTest():Void {
        /*
        // Useful for interpreting drop moves
        function hilightNodes(move, node) {
            var id:Int = state.nodes.indexOf(node);
            var addedNodes:Array<Int> = (cast move).addedNodes;
            if (addedNodes.indexOf(id) != -1) return '@';
            return null;
        }
        for (move in dropAction.moves) {
            trace(move);
            trace(state.spitBoard(plan, true, hilightNodes.bind(move)));
        }
        /**/
        
        var pieces:Pieces = new Pieces(Resource.getString('tables/pieces.json.txt'));

        // dropPiece, eatCells, decay, cavity, killHeadlessPlayer, oneLivingPlayer, endTurn, replenish, pickPiece, skipsExhausted

        config.buildParams.numPlayers = 2;
        config.pieceParams.pieceTableIDs = [pieces.getPieceIdBySizeAndIndex(3, 1)]; // '--- block'
        config.buildParams.initGrid = TestBoards.twoPlayerGrab;
        makeState();
        startAction.update();
        startAction.chooseMove();

        var occupier_:AspectPtr = plan.onNode(OwnershipAspect.OCCUPIER);

        VisualAssert.assert('two player grab', state.spitBoard(plan));

        dropAction.update();
        dropAction.chooseMove(110); // drop, eat

        VisualAssert.assert('player zero dropped an ---, ate player one\'s leg; small new cavity', state.spitBoard(plan));

        dropAction.update();
        dropAction.chooseMove(); // skip

        var head_:AspectPtr = plan.onPlayer(BodyAspect.HEAD);

        dropAction.update();
        dropAction.chooseMove(104); // drop, eat, kill
        
        VisualAssert.assert('player zero dropped another ---, ate player one\'s head and body; another cavity', state.spitBoard(plan));

        var winner_:AspectPtr = plan.onGlobal(WinAspect.WINNER);
        Assert.areEqual(0, state.global[winner_]);
    }

    private function makeState():Void {
        var basicRulesByName:Map<String, Rule> = config.makeRules();
        var random:Void->Float = function() return 0;
        combinedRules = ScourgeConfigFactory.combineRules(config, basicRulesByName);
        
        var builderRuleKeys:Array<String> = ScourgeConfigFactory.makeBuilderRuleList();
        var basicRules:Array<Rule> = [];
        var builderRules:Array<Rule> = [];

        for (key in basicRulesByName.keys().a2z()) {
            var builderRuleIndex:Int = builderRuleKeys.indexOf(key);
            if (builderRuleIndex == -1) basicRules.push(basicRulesByName[key]);
            else builderRules[builderRuleIndex] = basicRulesByName[key];
        }
        while (builderRules.remove(null)) {}

        // Plan the state
        plan = new StatePlanner().planState(state, builderRules.concat(basicRules));

        // Prime the rules
        for (rule in builderRules.concat(basicRules)) {
            rule.prime(state, plan, history, historyState, random);
        }

        startAction = combinedRules.get(ScourgeConfigFactory.makeStartAction());
        biteAction = combinedRules.get('biteAction');
        swapAction = combinedRules.get('swapAction');
        quitAction = combinedRules.get('quitAction');
        dropAction = combinedRules.get('dropAction');
    }

}
