package net.rezmason.scourge.model;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.utils.History;

using Lambda;

using net.rezmason.utils.Pointers;

class HistoryTest
{
    #if TIME_TESTS
    var time:Float;

    @Before
    public function setup():Void {
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace('tick $time');
    }
    #end

    @Test
    public function historyTest1():Void
    {
        var history:History<Null<Int>> = new History<Null<Int>>();

        Assert.areEqual(0, history.revision);
        Assert.areEqual(1, history.commit()); // Commit with no subscribers

        var propA:Int = history.alloc(0);
        var propB:Int = history.alloc(0);

        history.write(propA, 0);

        Assert.areEqual(2, history.commit()); // Commit with subscribers with no changes

        history.write(propA, 1);
        Assert.areEqual(3, history.commit()); // Commit
        history.write(propB, 2);
        Assert.areEqual(4, history.commit()); // Commit

        history.write(propA, 3);
        history.write(propB, 3);

        var propC:Int = history.alloc(3); // Late subscription

        Assert.areEqual(5, history.commit()); // Commit

        // current state
        Assert.areEqual(3, history.read(propA));
        Assert.areEqual(3, history.read(propB));
        Assert.areEqual(3, history.read(propC));

        // invalid revert
        try {
            history.revert(6);
            Assert.fail('Invalid revert failed to throw error');
        } catch (error:Dynamic) {}

        // revert to early state

        history.revert(4);
        Assert.areEqual(1, history.read(propA));
        Assert.areEqual(2, history.read(propB));
        Assert.areEqual(3, history.read(propC));

        Assert.areEqual(4, history.revision);

        // Pending changes
        history.write(propA, 4);
        history.write(propB, 5);
        history.write(propC, 6);

        // reset undoes pending changes
        history.reset();
        Assert.areEqual(1, history.read(propA));
        Assert.areEqual(2, history.read(propB));
        Assert.areEqual(3, history.read(propC));

        // revert to first state
        history.revert(0);
        Assert.areEqual(0, history.read(propA));
        Assert.areEqual(0, history.read(propB));
        Assert.areEqual(3, history.read(propC));

        Assert.areEqual(0, history.revision);

        history.write(propA, 1);
        history.write(propB, 2);
        history.write(propC, 3);
        Assert.areEqual(1, history.commit()); // Commit

        history.wipe();
        Assert.areEqual(0, history.revision);

        try {
            history.read(propA);
            Assert.fail('Bad get failed to throw error');
        } catch (error:Dynamic) {}

        var propD:Int = history.alloc(1);

        Assert.areEqual(1, history.commit()); // Commit after wipe

        var pointers:Array<Int> = [];

        for (ike in 0...100) pointers[ike] = history.alloc(1);

        history.forget();

        for (ike in 0...100) Assert.areEqual(1, history.read(pointers[ike]));
        Assert.areEqual(0, history.revision);

        history.wipe();

        var propE:Int = history.alloc(0);
        history.wipe();

        try {
            history.read(propE);
            Assert.fail('Bad get failed to throw error');
        } catch (error:Dynamic) {}

    }
}
