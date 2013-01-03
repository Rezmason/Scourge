package net.rezmason.scourge;

import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import massive.munit.util.Timer;

import haxe.Resource;

import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.model.ScourgeConfigFactory;

import net.rezmason.scourge.controller.Referee;
import net.rezmason.scourge.controller.Types;

class RefereeTest {

	var referee:Referee;

	public function new() {

	}

	@BeforeClass
	public function beforeClass():Void {
		referee = new Referee();
	}

	@AfterClass
	public function afterClass():Void {
		referee.endGame();
	}

	@Test
	public function allActionsRegisteredTest():Void {
		var playerCfg = [{type:Test}, {type:Test}, {type:Test}, {type:Test}];
		referee.beginGame(playerCfg, randomFunction, ScourgeConfigFactory.makeDefaultConfig());
		var referenceSaveGame:String = Resource.getString("serializedState");
		var saveGame:String = referee.saveGame().state.data;

		//trace(saveGame);
		Assert.areEqual(referenceSaveGame, saveGame + "\n");
	}

	private function randomFunction():Float { return 0; }
}
