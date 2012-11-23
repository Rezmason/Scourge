package net.rezmason.scourge.model;

import massive.munit.util.Timer;
import massive.munit.Assert;
import massive.munit.async.AsyncFactory;

import net.rezmason.scourge.model.ScourgeConfigMaker;

/**
* Auto generated MassiveUnit Test Class
*/
class GameTest
{


	public function new() {

	}

	@BeforeClass
	public function beforeClass():Void {

	}

	@AfterClass
	public function afterClass():Void {

	}

	@Before
	public function setup():Void {

	}

	@After
	public function tearDown():Void {

	}


	@Test
	public function testExample():Void {
		var configMaker = new ScourgeConfigMaker();
		var stateHistorian = new StateHistorian();
		var basicRules:Hash<Rule> = RuleFactory.makeBasicRules(configMaker.makeConfig(stateHistorian.history, stateHistorian.historyState));
		var combinedRules:Hash<Rule> = RuleFactory.combineRules(ScourgeConfigMaker.combinedRuleCfg, basicRules);
		for (action in ScourgeConfigMaker.actionList) Assert.isNotNull(combinedRules.get(action));
	}

	@Test
	public function startAction():Void {
		// decay, cavity, killHeadlessPlayer, oneLivingPlayer, pickPiece

		// Create a test board with a disconnected region, a cavity and headless opponent
	}

	@Test
	public function biteAction():Void {
		// bite, decay, cavity, killHeadlessPlayer, oneLivingPlayer

		// twoPlayerBite

		// Have one player bite the other
		// Then have the one bite the head of the other
	}

	@Test
	public function swapAction():Void {
		// swapPiece, pickPiece

		// Plain two-player
		// loop
		// 	swap a piece
		// 	check the new piece, and the number of pieces that remain

	}

	@Test
	public function quitAction():Void {
		// forfeit, decay, cavity, killHeadlessPlayer, oneLivingPlayer, endTurn, replenish, pickPiece

		// Two player grab with cavity
		// Have one player forfeit
	}

	@Test
	public function dropAction():Void {
		// dropPiece, eatCells, decay, cavity, killHeadlessPlayer, oneLivingPlayer, endTurn, replenish, pickPiece, skipsExhausted

		// twoPlayerGrab

		// Have one player eat a limb of the other
		// Have the other player skip
		// Have the one player eat the head of the other
	}

}
