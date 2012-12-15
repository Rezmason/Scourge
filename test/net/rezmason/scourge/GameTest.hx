package net.rezmason.scourge;

import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import massive.munit.util.Timer;

import net.rezmason.scourge.model.Game;
import net.rezmason.scourge.model.ScourgeConfigMaker;

class GameTest {

	var game:Game;
	var configMaker:ScourgeConfigMaker;

	public function new() {

	}

	@BeforeClass
	public function beforeClass():Void {
		configMaker = new ScourgeConfigMaker();
		game = new Game();
	}

	@AfterClass
	public function afterClass():Void {
		configMaker.reset();
		game.end();
	}

	@Before
	public function setup():Void {
		configMaker.reset();
		game.end();
	}

	@Test
	public function allActionsRegisteredTest():Void {
		game.begin(configMaker);
		trace(game.checksum);
	}
}