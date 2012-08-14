package net.rezmason.scourge.unused;

import massive.munit.Assert;

import net.rezmason.scourge.unused.History;
import net.rezmason.scourge.unused.Pointer;

class HistoryTest
{
	//@Test
	public function historyTest1():Void
	{
		var threwError:Bool;

		var history:History<Int> = new History<Int>();

		Assert.areEqual(0, history.revision);
		Assert.areEqual(0, history.commit()); // Commit with no subscribers

		var recordA:Pointer<Int> = new Pointer<Int>();
		var recordB:Pointer<Int> = new Pointer<Int>();
		var recordC:Pointer<Int> = new Pointer<Int>();

		recordA.value = 0;

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

		// revert to early state
		history.revert(2);
		Assert.areEqual(1, recordA.value);
		Assert.areEqual(2, recordB.value);
		Assert.areEqual(3, recordC.value);

		Assert.areEqual(2, history.revision);

		// Pending changes
		recordA.value = 4;
		recordB.value = 5;
		recordC.value = 6;

		#if SAFE_HISTORY
			// Attempt to revert with pending changes
			threwError = false;
			try {
				history.revert(1);
			} catch (error:Dynamic) {
				threwError = true;
			}
			Assert.isTrue(threwError);
		#end

		// reset undoes pending changes
		history.reset();
		Assert.areEqual(1, recordA.value);
		Assert.areEqual(2, recordB.value);
		Assert.areEqual(3, recordC.value);

		// revert to first state
		history.revert(0);
		Assert.areEqual(0, recordA.value);
		Assert.areEqual(null, recordB.value);
		Assert.areEqual(3, recordC.value);

		Assert.areEqual(0, history.revision);

		recordA.value = 1;
		recordB.value = 2;
		recordC.value = 3;
		Assert.areEqual(1, history.commit()); // Commit

		history.wipe();
		Assert.areEqual(0, history.revision);

		var recordD:Pointer<Int> = new Pointer<Int>();
		recordD.value = 1;	// subscriber after wipe
		history.add(recordD);
		recordA.value = -1;
		recordB.value = -1;
		recordC.value = -1;

		Assert.areEqual(0, history.commit()); // Commit after wipe

	}
}
