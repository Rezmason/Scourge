package net.rezmason.utils;

import massive.munit.Assert;

using net.rezmason.utils.Pointers;

class PointersTest {

    var time:Float;

	@Before
    public function setup():Void {
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace(time);
    }

	@Test
	public function testExample():Void
	{
		//Assert.isTrue(false);

		var arr1:Array<Int> = [0, 1, 2, 3, 4];
		var arr2:Array<Ptr<Int>> = [arr1.ptr(4), arr1.ptr(3), arr1.ptr(2), arr1.ptr(1), arr1.ptr(0)];
		var arr3:Array<Ptr<Ptr<Int>>> = [arr2.ptr(0), arr2.ptr(2), arr2.ptr(4)];

		Assert.areEqual(4, arr1.at(arr2.at(arr3[0])));

		arr1.mod(arr2.at(arr3[0]), 5);

		Assert.areEqual(5, arr1[4]);

		Assert.areEqual(5, arr3[0].d(arr2).d(arr1));

		arr1.mod(arr3[0].d(arr2), 3);
		Assert.areEqual(3, arr1[4]);

		var fancy:Ptr<Int> = 0.pointerArithmetic();

		Assert.areEqual(arr1[0], fancy.d(arr1));

        // Throws compiler error:
        //arr3[0].d(arr1);
        //arr1.at(arr3[0]);

	}
}
