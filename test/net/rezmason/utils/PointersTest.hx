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
        //Assert.isTrue(false);

        var arr1:PtrSet<Int> = new PtrSet([0, 1, 2, 3, 4]);
        var arr2:PtrSet<Ptr<Int>> = new PtrSet([arr1.ptr(4), arr1.ptr(3), arr1.ptr(2), arr1.ptr(1), arr1.ptr(0)]);
        var arr3:PtrSet<Ptr<Ptr<Int>>> = new PtrSet([arr2.ptr(0), arr2.ptr(2), arr2.ptr(4)]);

        Assert.areEqual(4, arr1[arr2[arr3[arr3.ptr(0)]]]);

        arr1[arr2[arr3[arr3.ptr(0)]]] = 5;

        arr1[arr2[arr3[arr3.ptr(0)]]] = 5;

        arr1[arr1.ptr(0)] = 1;

        Assert.areEqual(5, arr1[arr1.ptr(4)]);

        var fancy:Ptr<Int> = Ptr.intToPointer(0);

        // Throws compiler error:
        //arr1[arr3[0]);

    }
}
