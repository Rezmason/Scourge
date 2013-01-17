package net.rezmason.scourge;

import massive.munit.Assert;
import massive.munit.async.AsyncFactory;
import massive.munit.util.Timer;

import haxe.Resource;

import net.rezmason.scourge.model.ScourgeConfig;
import net.rezmason.scourge.model.ScourgeConfigFactory;

import net.rezmason.scourge.controller.Referee;
import net.rezmason.scourge.controller.Types;

using net.rezmason.scourge.model.BoardUtils;
class RefereeTest {

	var referee:Referee;
	var playerCfgs:Array<PlayerConfig>;

	public function new() {

	}

	@BeforeClass
	public function beforeClass():Void {
		referee = new Referee();
	}

	@AfterClass
	public function afterClass():Void {

	}

	@Ignore("Runs too slow on NekoVM") @Test
	public function serializeTest():Void {
		playerCfgs = [{type:Test(null, false)}, {type:Test(null, false)}, {type:Test(null, false)}, {type:Test(null, false)}];
		referee.beginGame(playerCfgs, randomFunction, ScourgeConfigFactory.makeDefaultConfig());

		var savedGame = referee.saveGame();
		var data:String = savedGame.state.data;
		//trace(data);
		Assert.areEqual(Resource.getString("serializedState"), data + "\n");
	}

	@Test
	public function saveTest():Void {

		var deferredCalls = [];

		function defer(func) {
			deferredCalls.push(func);
		}

		playerCfgs = [{type:Test(defer, true)}, {type:Test(defer, false)}, {type:Test(defer, false)}, {type:Test(defer, false)}];

		Assert.isFalse(referee.gameBegun);
		referee.beginGame(playerCfgs, randomFunction, ScourgeConfigFactory.makeDefaultConfig());
		Assert.isTrue(referee.gameBegun);

		for (ike in 0...10)
		{
			var oldDeferredCalls = deferredCalls;
			deferredCalls = [];
			var then = Timer.stamp();
			//trace([ike, oldDeferredCalls.length, Std.int(then * 1000)]);

			for (call in oldDeferredCalls) {
				call();

				var now = Timer.stamp();
				//trace(Std.int((now - then) * 1000));
				then = now;
			}
		}

		var savedGame = referee.saveGame();
		var board = referee.spitBoard();

		//trace(board);

		referee.endGame();
		Assert.isFalse(referee.gameBegun);

		referee.resumeGame(playerCfgs, randomFunction, savedGame);
		Assert.isTrue(referee.gameBegun);

		Assert.areEqual(board, referee.spitBoard());

		referee.endGame();
		Assert.isFalse(referee.gameBegun);
	}

	private function randomFunction():Float { return 0; }
}
