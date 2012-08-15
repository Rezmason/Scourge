package net.rezmason.scourge.unused;

import massive.munit.Assert;

import net.rezmason.scourge.unused.PointerHistory;
import net.rezmason.scourge.unused.Pointer;

class PointerHistoryTest
{
	//@Test
	public function historyTest1():Void
	{
		var threwError:Bool;

		var history:PointerHistory<Int> = new PointerHistory<Int>();

		Assert.areEqual(0, history.revision);
		Assert.areEqual(0, history.commit()); // Commit with no subscribers

		var propA:Pointer<Int> = new Pointer<Int>();
		var propB:Pointer<Int> = new Pointer<Int>();
		var propC:Pointer<Int> = new Pointer<Int>();

		propA.value = 0;

		history.add(propA);
		history.add(propB);

		Assert.areEqual(0, history.commit()); // Commit with subscribers with no changes

		propA.value = 1;
		Assert.areEqual(1, history.commit()); // Commit
		propB.value = 2;
		Assert.areEqual(2, history.commit()); // Commit

		propA.value = 3;
		propB.value = 3;
		propC.value = 3;

		history.add(propC); // Late subscription

		Assert.areEqual(3, history.commit()); // Commit

		// current state
		Assert.areEqual(3, propA.value);
		Assert.areEqual(3, propB.value);
		Assert.areEqual(3, propC.value);

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
		Assert.areEqual(1, propA.value);
		Assert.areEqual(2, propB.value);
		Assert.areEqual(3, propC.value);

		Assert.areEqual(2, history.revision);

		// Pending changes
		propA.value = 4;
		propB.value = 5;
		propC.value = 6;

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
		Assert.areEqual(1, propA.value);
		Assert.areEqual(2, propB.value);
		Assert.areEqual(3, propC.value);

		// revert to first state
		history.revert(0);
		Assert.areEqual(0, propA.value);
		Assert.areEqual(null, propB.value);
		Assert.areEqual(3, propC.value);

		Assert.areEqual(0, history.revision);

		propA.value = 1;
		propB.value = 2;
		propC.value = 3;
		Assert.areEqual(1, history.commit()); // Commit

		history.wipe();
		Assert.areEqual(0, history.revision);

		var propD:Pointer<Int> = new Pointer<Int>();
		propD.value = 1;	// subscriber after wipe
		history.add(propD);
		propA.value = -1;
		propB.value = -1;
		propC.value = -1;

		Assert.areEqual(0, history.commit()); // Commit after wipe

	}
}
