package net.rezmason.scourge.model;

import massive.munit.Assert;

class PlayersTest
{
    var time:Float;

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
	public function testExample():Void
	{
		//Assert.areEqual(stateCfg.numPlayers, state.players.length);
	}
}
