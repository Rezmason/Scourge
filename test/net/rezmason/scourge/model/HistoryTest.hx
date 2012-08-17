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

        var history:History<Int> = new History<Int>();

        Assert.areEqual(0, history.revision);
        Assert.areEqual(1, history.commit()); // Commit with no subscribers

        var historyArray:Array<Int> = history.array;

        var propA:Int = history.alloc(0);
        var propB:Int = history.alloc(0);
        var propC:Int = -1;

        historyArray[propA] = 0;

        Assert.areEqual(2, history.commit()); // Commit with subscribers with no changes

        historyArray[propA] = 1;
        Assert.areEqual(3, history.commit()); // Commit
        historyArray[propB] = 2;
        Assert.areEqual(4, history.commit()); // Commit

        historyArray[propA] = 3;
        historyArray[propB] = 3;

        propC = history.alloc(3); // Late subscription

        Assert.areEqual(5, history.commit()); // Commit

        // current state
        Assert.areEqual(3, historyArray[propA]);
        Assert.areEqual(3, historyArray[propB]);
        Assert.areEqual(3, historyArray[propC]);

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
        Assert.areEqual(1, historyArray[propA]);
        Assert.areEqual(2, historyArray[propB]);
        Assert.areEqual(null, historyArray[propC]);

        Assert.areEqual(4, history.revision);

        // Pending changes
        historyArray[propA] = 4;
        historyArray[propB] = 5;
        historyArray[propC] = 6;

        // reset undoes pending changes
        history.reset();
        Assert.areEqual(1, historyArray[propA]);
        Assert.areEqual(2, historyArray[propB]);
        Assert.areEqual(null, historyArray[propC]);

        // revert to first state
        history.revert(0);
        Assert.areEqual(null, historyArray[propA]);
        Assert.areEqual(null, historyArray[propB]);
        Assert.areEqual(null, historyArray[propC]);

        Assert.areEqual(0, history.revision);

        historyArray[propA] = 1;
        historyArray[propB] = 2;
        historyArray[propC] = 3;
        Assert.areEqual(1, history.commit()); // Commit

        history.wipe();
        Assert.areEqual(0, history.revision);
        for (ike in historyArray) Assert.isNull(ike);

        var propD:Int = history.alloc(1);

        Assert.areEqual(1, history.commit()); // Commit after wipe

        for (ike in 0...100) history.alloc(1);

        history.forget();

        Assert.isTrue(historyArray.has(1));
        Assert.areEqual(0, history.revision);

        history.wipe();

        Assert.isFalse(historyArray.has(1));

    }
}
