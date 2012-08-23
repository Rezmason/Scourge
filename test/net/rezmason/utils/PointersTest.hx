package net.rezmason.utils;

import massive.munit.Assert;

using net.rezmason.utils.Pointers;

class PointersTest
{

	@Test
	public function testExample():Void
	{
		//Assert.isTrue(false);

		var arr1:Array<Int> = [0, 1, 2, 3, 4];
		var arr2:Array<Pointer<Int>> = [arr1.ptr(4), arr1.ptr(3), arr1.ptr(2), arr1.ptr(1), arr1.ptr(0)];
		var arr3:Array<Pointer<Pointer<Int>>> = [arr2.ptr(0), arr2.ptr(2), arr2.ptr(4)];

		Assert.areEqual(4, arr3[0].d(arr2).d(arr1));

        // Throws compiler error:
        //arr3.d(arr1);

	}
}
