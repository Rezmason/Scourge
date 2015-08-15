package net.rezmason.scourge.game;

import massive.munit.Assert;
import VisualAssert;
import net.rezmason.grid.GridDirection.*;
import net.rezmason.grid.Cell;

using net.rezmason.grid.GridUtils;

class GridUtilsTest {

    var spaceItr:Int;
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
    public function rowTest():Void {
        spaceItr = 0;

        var space:Cell<Int> = makeSpace();
        var first:Cell<Int> = space;
        Assert.areEqual(0, space.value);
        for (i in 1...10) space = space.attach(makeSpace(), E);
        var last:Cell<Int> = space;
        Assert.areEqual(10 - 1, space.run(E).value);
        Assert.areEqual(last, first.run(E));
        Assert.areEqual(first, last.run(W));

        spaceItr = 10;
        for (n in space.walk(W)) Assert.areEqual(n.value, --spaceItr);

        var ike:Int = 0;

        for (n in last.walk(W)) ike++;
        Assert.areEqual(10, ike);

        ike = 0;
        for (n in first.walk(E)) ike++;
        Assert.areEqual(10, ike);

        Assert.areEqual(10, first.getGridSequence().length);

        Assert.areEqual(5, first.getGridSequence(underFiveOnly).length);
    }

    function underFiveOnly(val:Int, connection:Int):Bool { return val < 5; }

    function makeSpace():Cell<Int> {
        var space:Cell<Int> = new Cell<Int>(spaceItr, spaceItr);
        spaceItr++;
        return space;
    }
}
