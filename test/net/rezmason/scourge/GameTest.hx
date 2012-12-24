package net.rezmason.scourge;

import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import massive.munit.util.Timer;

import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.model.ScourgeConfigFactory;

import net.rezmason.scourge.controller.Referee;

class GameTest {

	var game:Game;

	public function new() {

	}

	@BeforeClass
	public function beforeClass():Void {
		game = new Game();
	}

	@AfterClass
	public function afterClass():Void {
		game.end();
	}

	@Test
	public function allActionsRegisteredTest():Void {
		game.begin(ScourgeConfigFactory.makeDefaultConfig());
		trace(game.checksum);
	}
}
