package net.rezmason.scourge.model.meta;

import massive.munit.Assert;
import VisualAssert;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.scourge.model.meta.ReplenishableAspect;
import net.rezmason.scourge.model.meta.ReplenishRule;
import net.rezmason.scourge.model.test.TestAspect;

using net.rezmason.praxis.state.StatePlan;
using net.rezmason.utils.Pointers;

class ReplenishRuleTest extends ScourgeRuleTest
{

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
    public function replenishTest():Void {
        var params:ReplenishParams = {
            globalProperties:null,
            playerProperties:null,
            nodeProperties:null,
        };

        params.globalProperties = [
            TestAspect.VALUE_1.id => { prop:TestAspect.VALUE_1, amount:1, period:1, maxAmount:3, },
            TestAspect.VALUE_2.id => { prop:TestAspect.VALUE_2, amount:1, period:3, maxAmount:5, },
            TestAspect.VALUE_3.id => { prop:TestAspect.VALUE_3, amount:2, period:3, maxAmount:10, },
        ];

        params.playerProperties = [
            TestAspect.VALUE_1.id => { prop:TestAspect.VALUE_1, amount:1, period:1, maxAmount:3, },
            TestAspect.VALUE_2.id => { prop:TestAspect.VALUE_2, amount:1, period:3, maxAmount:5, },
            TestAspect.VALUE_3.id => { prop:TestAspect.VALUE_3, amount:2, period:3, maxAmount:10, },
        ];

        params.nodeProperties = [
            TestAspect.VALUE_1.id => { prop:TestAspect.VALUE_1, amount:1, period:1, maxAmount:3, },
            TestAspect.VALUE_2.id => { prop:TestAspect.VALUE_2, amount:1, period:3, maxAmount:5, },
            TestAspect.VALUE_3.id => { prop:TestAspect.VALUE_3, amount:2, period:3, maxAmount:10, },
        ];

        var replenishRule:ReplenishRule = new ReplenishRule();
        replenishRule.init(params);

        makeState([replenishRule], 1, TestBoards.emptyPetri);

        var stateValue1_:AspectPtr = plan.onGlobal(TestAspect.VALUE_1);
        var stateValue2_:AspectPtr = plan.onGlobal(TestAspect.VALUE_2);
        var stateValue3_:AspectPtr = plan.onGlobal(TestAspect.VALUE_3);

        var playerValue1_:AspectPtr = plan.onPlayer(TestAspect.VALUE_1);
        var playerValue2_:AspectPtr = plan.onPlayer(TestAspect.VALUE_2);
        var playerValue3_:AspectPtr = plan.onPlayer(TestAspect.VALUE_3);

        var nodeValue1_:AspectPtr = plan.onNode(TestAspect.VALUE_1);
        var nodeValue2_:AspectPtr = plan.onNode(TestAspect.VALUE_2);
        var nodeValue3_:AspectPtr = plan.onNode(TestAspect.VALUE_3);

        var expectedValues1:Array<Int> = [0,1,2,3,];
        var expectedValues2:Array<Int> = [0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,];
        var expectedValues3:Array<Int> = [0,0,0,2,2,2,4,4,4,6,6,6,8,8,8,10,10,10,];

        for (ike in 0...50) {

            var index1:Int = Std.int(Math.min(expectedValues1.length - 1, ike));
            var index2:Int = Std.int(Math.min(expectedValues2.length - 1, ike));
            var index3:Int = Std.int(Math.min(expectedValues3.length - 1, ike));

            Assert.areEqual(expectedValues1[index1], state.global[stateValue1_]);
            Assert.areEqual(expectedValues2[index2], state.global[stateValue2_]);
            Assert.areEqual(expectedValues3[index3], state.global[stateValue3_]);

            for (player in state.players) {
                Assert.areEqual(expectedValues1[index1], player[playerValue1_]);
                Assert.areEqual(expectedValues2[index2], player[playerValue2_]);
                Assert.areEqual(expectedValues3[index3], player[playerValue3_]);
            }

            for (node in state.nodes) {
                Assert.areEqual(expectedValues1[index1], node[nodeValue1_]);
                Assert.areEqual(expectedValues2[index2], node[nodeValue2_]);
                Assert.areEqual(expectedValues3[index3], node[nodeValue3_]);
            }

            replenishRule.chooseMove();
        }
    }
}
