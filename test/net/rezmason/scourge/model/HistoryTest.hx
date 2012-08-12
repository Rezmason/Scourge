package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.History;
import net.rezmason.scourge.model.Record;

class HistoryTest
{
	@Test
	public function historyTest1():Void
	{
		var threwError:Bool;

		var history:History<Int> = new History<Int>();

		Assert.areEqual(0, history.currentRev);
		Assert.areEqual(0, history.commit()); // Commit with no subscribers

		var recordA:Record<Int> = new Record<Int>();
		var recordB:Record<Int> = new Record<Int>();
		var recordC:Record<Int> = new Record<Int>();

		history.add(recordA);
		history.add(recordB);

		Assert.areEqual(0, history.commit()); // Commit with subscribers with no changes

		recordA.value = 1;
		Assert.areEqual(1, history.commit()); // Commit
		recordB.value = 2;
		Assert.areEqual(2, history.commit()); // Commit

		recordA.value = 3;
		recordB.value = 3;
		recordC.value = 3;

		history.add(recordC); // Late subscription

		Assert.areEqual(3, history.commit()); // Commit

		// current state
		Assert.areEqual(3, recordA.value);
		Assert.areEqual(3, recordB.value);
		Assert.areEqual(3, recordC.value);

		// invalid revert
		threwError = false;
		try {
			history.revert(4);
		} catch (error:Dynamic) {
			threwError = true;
		}
		Assert.isTrue(threwError);

		// first state
		history.revert(0);
		Assert.areEqual(0, recordA.value);
		Assert.areEqual(0, recordB.value);
		Assert.areEqual(3, recordC.value);

		// middle state
		history.revert(2);
		Assert.areEqual(1, recordA.value);
		Assert.areEqual(2, recordB.value);
		Assert.areEqual(3, recordC.value);

		// Pending changes
		recordA.value = 4;
		recordB.value = 5;
		recordC.value = 6;

		// Attempt to revert with pending changes
		threwError = false;
		try {
			history.revert(history.latestRev);
		} catch (error:Dynamic) {
			threwError = true;
		}
		Assert.isTrue(threwError);

		// reset undoes pending changes
		history.reset();
		Assert.areEqual(1, recordA.value);
		Assert.areEqual(2, recordB.value);
		Assert.areEqual(3, recordC.value);

		// invalid revert after cut
		history.cut();
		threwError = false;
		try {
			history.revert(3);
		} catch (error:Dynamic) {
			threwError = true;
		}
		Assert.isTrue(threwError);

		history.wipe();
		var recordD:Record<Int> = new Record<Int>();
		recordD.value = 1;	// subscriber after wipe
		history.add(recordD);
		recordA.value = -1;
		recordB.value = -1;
		recordC.value = -1;

		Assert.areEqual(0, history.commit()); // Commit after wipe

	}
}
