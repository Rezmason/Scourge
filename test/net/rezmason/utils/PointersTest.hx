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
		var arr2:Array<Pointer<Int>> = [arr1.addr(4), arr1.addr(3), arr1.addr(2), arr1.addr(1), arr1.addr(0)];
		var arr3:Array<Pointer<Pointer<Int>>> = [arr2.addr(0), arr2.addr(2), arr2.addr(4)];

		Assert.areEqual(4, trace(arr3[0].d(arr2).d(arr1)));

	}
}
