package net.rezmason.scourge.model;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.ropes.GridNode;

using net.rezmason.ropes.GridUtils;

class GridUtilsTest {

    var nodeItr:Int;
    #if TIME_TESTS
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
    #end

    @Test
    public function rowTest():Void {
        nodeItr = 0;

        var node:GridNode<Int> = makeNode();
        var first:GridNode<Int> = node;
        Assert.areEqual(0, node.value);
        for (i in 1...10) node = node.attach(makeNode(), Gr.e);
        var last:GridNode<Int> = node;
        Assert.areEqual(10 - 1, node.run(Gr.e).value);
        Assert.areEqual(last, first.run(Gr.e));
        Assert.areEqual(first, last.run(Gr.w));

        nodeItr = 10;
        for (n in node.walk(Gr.w)) Assert.areEqual(n.value, --nodeItr);

        var ike:Int = 0;

        for (n in last.walk(Gr.w)) ike++;
        Assert.areEqual(10, ike);

        ike = 0;
        for (n in first.walk(Gr.e)) ike++;
        Assert.areEqual(10, ike);

        Assert.areEqual(10, first.getGraph().length);

        Assert.areEqual(5, first.getGraph(underFiveOnly).length);
    }

    function underFiveOnly(val:Int, connection:Int):Bool { return val < 5; }

    function makeNode():GridNode<Int> {
        var node:GridNode<Int> = new GridNode<Int>(nodeItr++);
        return node;
    }
}
