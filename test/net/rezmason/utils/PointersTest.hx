package net.rezmason.utils;

import massive.munit.Assert;

using net.rezmason.utils.Pointers;

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

        var key = Pointers.makeSet();

		var arr1:PtrArray<Int> = new PtrArray([0, 1, 2, 3, 4]);
		var arr2:PtrArray<Ptr<Int>> = new PtrArray([arr1.ptr(4, key), arr1.ptr(3, key), arr1.ptr(2, key), arr1.ptr(1, key), arr1.ptr(0, key)]);
		var arr3:PtrArray<Ptr<Ptr<Int>>> = new PtrArray([arr2.ptr(0, key), arr2.ptr(2, key), arr2.ptr(4, key)]);

		Assert.areEqual(4, arr1.at(arr2.at(arr3[0])));

		arr1.mod(arr2.at(arr3[0]), 5);

        arr1.mod(arr2.at(arr3[0]), 5);

		Assert.areEqual(5, arr1[4]);

		var fancy:Ptr<Int> = 0.intToPointer(key);

        // Throws compiler error:
        //arr1.at(arr3[0]);

	}
}
