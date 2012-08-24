package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.History;

using Lambda;

class HistoryTest
{
    @Test
    public function historyTest1():Void
    {
        var threwError:Bool;

        var history:History<Null<Int>> = new History<Null<Int>>();

        Assert.areEqual(0, history.revision);
        Assert.areEqual(1, history.commit()); // Commit with no subscribers

        var propA:Int = history.alloc(0);
        var propB:Int = history.alloc(0);
        var propC:Int = -1;

        history.set(propA, 0);

        Assert.areEqual(2, history.commit()); // Commit with subscribers with no changes

        history.set(propA, 1);
        Assert.areEqual(3, history.commit()); // Commit
        history.set(propB, 2);
        Assert.areEqual(4, history.commit()); // Commit

        history.set(propA, 3);
        history.set(propB, 3);

        propC = history.alloc(3); // Late subscription

        Assert.areEqual(5, history.commit()); // Commit

        // current state
        Assert.areEqual(3, history.get(propA));
        Assert.areEqual(3, history.get(propB));
        Assert.areEqual(3, history.get(propC));

        // invalid revert
        threwError = false;
        try {
            history.revert(6);
        } catch (error:Dynamic) {
            threwError = true;
        }
        Assert.isTrue(threwError);

        // revert to early state

        history.revert(4);
        Assert.areEqual(1, history.get(propA));
        Assert.areEqual(2, history.get(propB));
        Assert.areEqual(null, history.get(propC));

        Assert.areEqual(4, history.revision);

        // Pending changes
        history.set(propA, 4);
        history.set(propB, 5);
        history.set(propC, 6);

        // reset undoes pending changes
        history.reset();
        Assert.areEqual(1, history.get(propA));
        Assert.areEqual(2, history.get(propB));
        Assert.areEqual(null, history.get(propC));

        // revert to first state
        history.revert(0);
        Assert.areEqual(null, history.get(propA));
        Assert.areEqual(null, history.get(propB));
        Assert.areEqual(null, history.get(propC));

        Assert.areEqual(0, history.revision);

        history.set(propA, 1);
        history.set(propB, 2);
        history.set(propC, 3);
        Assert.areEqual(1, history.commit()); // Commit

        history.wipe();
        Assert.areEqual(0, history.revision);
        for (ike in 0...history.length) Assert.isNull(history.get(ike));

        var propD:Int = history.alloc(1);

        Assert.areEqual(1, history.commit()); // Commit after wipe

        for (ike in 0...100) history.alloc(1);

        history.forget();

        for (ike in 0...100) Assert.areEqual(1, history.get(ike));
        Assert.areEqual(0, history.revision);

        history.wipe();

        threwError = false;
        try {
            history.get(0);
        } catch (error:Dynamic) {
            threwError = true;
        }

        Assert.isTrue(threwError);

    }
}
