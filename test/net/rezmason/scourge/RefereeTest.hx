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

	}

	//@AsyncTest
	@Test
	public function saveTest(/*factory:AsyncFactory*/):Void {

		//var handler = factory.createHandler(this, onSaveTestComplete, 300);

		var playerCfg = [{type:Test}, {type:Test}, {type:Test}, {type:Test}];

		Assert.isFalse(referee.gameBegun);
		referee.beginGame(playerCfg, randomFunction, ScourgeConfigFactory.makeDefaultConfig());
		Assert.isTrue(referee.gameBegun);

		var referenceSaveGame:String = Resource.getString("serializedState");
		var savedGame = referee.saveGame();
		var data:String = savedGame.state.data;
		//trace(data);
		Assert.areEqual(referenceSaveGame, data + "\n");

		referee.endGame();
		Assert.isFalse(referee.gameBegun);

		referee.resumeGame(playerCfg, randomFunction, savedGame);
		Assert.isTrue(referee.gameBegun);

		// Resumed game

		referee.endGame();
		Assert.isFalse(referee.gameBegun);
	}

	private function onSaveTestComplete():Void {

	}

	private function randomFunction():Float { return 0; }
}
