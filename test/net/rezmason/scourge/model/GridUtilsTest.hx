package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.GridNode;

using net.rezmason.scourge.model.GridUtils;

class GridUtilsTest {

    var nodeItr:Int;

    @Before
    public function setup():Void {
        nodeItr = 0;
    }

    @After
    public function tearDown():Void {

    }

    @Test
    public function rowTest():Void {
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
    }

    function makeNode():GridNode<Int> {
        var node:GridNode<Int> = new GridNode<Int>(nodeItr++);
        return node;
    }
}
