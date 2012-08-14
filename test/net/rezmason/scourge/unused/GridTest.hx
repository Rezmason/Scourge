package net.rezmason.scourge.unused;

import massive.munit.Assert;

typedef TestCell = {str:String, symbol:String};

class GridTest {
    private var grid:Grid<TestCell>;

    @Before
    public function setup():Void {

    }

    @After
    public function tearDown():Void {

    }

    //@Test
    public function spitTest():Void {
        grid = new Grid<TestCell>(4, 3, gen);

        Assert.areEqual(4, grid.width);
        Assert.areEqual(3, grid.height);

        Assert.areEqual("\n" +
            "0/0 1/0 2/0 3/0 \n" +
            "0/1 1/1 2/1 3/1 \n" +
            "0/2 1/2 2/2 3/2 \n" ,
            "\n" + grid.spit(printStr)
        );

        Assert.isFalse(grid.disposed);
        grid.dispose();
        Assert.isTrue(grid.disposed);
        Assert.areEqual(null, grid.spit(printStr));
        grid = null;
    }

    //@Test
    public function iteratorTest():Void {
        grid = new Grid<TestCell>(5, 3, gen);

        Assert.areEqual("\n" +
            "o o o o o \n" +
            "o o o o o \n" +
            "o o o o o \n" ,
            "\n" + grid.spit(printSymbol)
        );

        enumerate(grid.getOrthogonalSlicesForIndex(7), "+");
        Assert.areEqual("\n" +
            "o o + o o \n" +
            "+ + + + + \n" +
            "o o + o o \n" ,
            "\n" + grid.spit(printSymbol)
        );

        enumerate(grid.getDiagonalSlicesForIndex(7), "X");
        Assert.areEqual("\n" +
            "o X + X o \n" +
            "+ + X + + \n" +
            "o X + X o \n" ,
            "\n" + grid.spit(printSymbol)
        );

        enumerate(grid.getSlicesForIndex(7), "*");
        Assert.areEqual("\n" +
            "o * * * o \n" +
            "* * * * * \n" +
            "o * * * o \n" ,
            "\n" + grid.spit(printSymbol)
        );

        enumerate(grid.getSlicesForIndex(0), "?");
        Assert.areEqual("\n" +
            "? ? ? ? ? \n" +
            "? ? * * * \n" +
            "? * ? * o \n" ,
            "\n" + grid.spit(printSymbol)
        );

        enumerate(grid.getSlicesForIndex(14), "!");
        Assert.areEqual("\n" +
            "? ? ! ? ! \n" +
            "? ? * ! ! \n" +
            "! ! ! ! ! \n" ,
            "\n" + grid.spit(printSymbol)
        );

        enumerate(grid.getSlicesForIndex(13), "$");
        Assert.areEqual("\n" +
            "? $ ! $ ! \n" +
            "? ? $ $ $ \n" +
            "$ $ $ $ $ \n" ,
            "\n" + grid.spit(printSymbol)
        );

        grid.dispose();
        grid = null;
    }

    //@Test
    public function iteratorTest2():Void {
        grid = new Grid<TestCell>(20, 20, gen);

        enumerate(grid.getSlicesForIndex(210), "•");

        Assert.areEqual("\n" +
            "• o o o o o o o o o • o o o o o o o o o \n" +
            "o • o o o o o o o o • o o o o o o o o • \n" +
            "o o • o o o o o o o • o o o o o o o • o \n" +
            "o o o • o o o o o o • o o o o o o • o o \n" +
            "o o o o • o o o o o • o o o o o • o o o \n" +
            "o o o o o • o o o o • o o o o • o o o o \n" +
            "o o o o o o • o o o • o o o • o o o o o \n" +
            "o o o o o o o • o o • o o • o o o o o o \n" +
            "o o o o o o o o • o • o • o o o o o o o \n" +
            "o o o o o o o o o • • • o o o o o o o o \n" +
            "• • • • • • • • • • • • • • • • • • • • \n" +
            "o o o o o o o o o • • • o o o o o o o o \n" +
            "o o o o o o o o • o • o • o o o o o o o \n" +
            "o o o o o o o • o o • o o • o o o o o o \n" +
            "o o o o o o • o o o • o o o • o o o o o \n" +
            "o o o o o • o o o o • o o o o • o o o o \n" +
            "o o o o • o o o o o • o o o o o • o o o \n" +
            "o o o • o o o o o o • o o o o o o • o o \n" +
            "o o • o o o o o o o • o o o o o o o • o \n" +
            "o • o o o o o o o o • o o o o o o o o • \n" ,
            "\n" + grid.spit(printSymbol)
        );

        grid.dispose();
        grid = null;
    }

    private function gen(column:Int, row:Int):TestCell {
        return {str:"" + column + "/" + row, symbol:"o"};
    }

    private function printStr(cell:TestCell):String { return cell.str; }
    private function printSymbol(cell:TestCell):String { return cell.symbol; }

    private function enumerate(slices:Iterable<Iterator<TestCell>>, symbol:String):Void
    {
        for (slice in slices) {
            for (cell in slice) {
                cell.symbol = symbol;
            }
        }
    }
}
