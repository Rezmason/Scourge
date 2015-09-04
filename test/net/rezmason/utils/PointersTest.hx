package net.rezmason.utils;

import massive.munit.Assert;

using net.rezmason.utils.pointers.Pointers;

class PointersTest {

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
    public function testExample():Void
    {
        var src1 = new PointerSource();
        var ptrs1 = [for (ike in 0...5) src1.add()];
        var src2 = new PointerSource();
        var ptrs2 = [for (ike in 0...5) src2.add()];
        var src3 = new PointerSource();
        var ptrs3 = [for (ike in 0...5) src3.add()];

        var arr1:Pointable<String> = new Pointable(['a', 'b', 'c', 'd', 'e']);
        var arr2:Pointable<Ptr<String>> = new Pointable([ptrs1[4], ptrs1[3], ptrs1[2], ptrs1[1], ptrs1[0]]);
        var arr3:Pointable<Ptr<Ptr<String>>> = new Pointable([ptrs2[0], ptrs2[2], ptrs2[4]]);

        Assert.areEqual('e', arr1[arr2[arr3[ptrs3[0]]]]);
        
        arr1[arr2[arr3[ptrs3[0]]]] = 'f';
        arr1[ptrs1[0]] = 'b';
        Assert.areEqual('f', arr1[ptrs1[4]]);
    }
}
