package net.rezmason.scourge.model;

import massive.munit.Assert;

class StageHistorianTest {

	var time:Float;

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
	public function transferAndCommitTest():Void {
		// Create a state - twoPlayerGrab
		// Commit it
		// Change it - freshen and eat body (non-recursive)
		// Commit it
		// Change it - freshen and eat head (non-recursive)
		// Commit it

		// revert
		// Assert
		// revert
		// Assert
		// revert
		// Assert
	}
}
