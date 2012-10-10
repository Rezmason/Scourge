package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.ReplenishableAspect;
import net.rezmason.scourge.model.aspects.TestAspect;
import net.rezmason.scourge.model.rules.ReplenishRule;

using net.rezmason.utils.Pointers;

class ReplenishRuleTest extends RuleTest
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
        trace("tick " + time);
    }
    #end

    @Test
    public function replenishTest():Void {
        var cfg:ReplenishConfig = {
            history:history,
            historyState:historyState,
            stateProperties:null,
            playerProperties:null,
            nodeProperties:null,
        };

        cfg.stateProperties = [
            { prop:TestAspect.VALUE_1, amount:1, period:1, maxAmount:3, },
            { prop:TestAspect.VALUE_2, amount:1, period:3, maxAmount:5, },
            { prop:TestAspect.VALUE_3, amount:2, period:3, maxAmount:10, },
        ];

        cfg.playerProperties = [
            { prop:TestAspect.VALUE_1, amount:1, period:1, maxAmount:3, },
            { prop:TestAspect.VALUE_2, amount:1, period:3, maxAmount:5, },
            { prop:TestAspect.VALUE_3, amount:2, period:3, maxAmount:10, },
        ];

        cfg.nodeProperties = [
            { prop:TestAspect.VALUE_1, amount:1, period:1, maxAmount:3, },
            { prop:TestAspect.VALUE_2, amount:1, period:3, maxAmount:5, },
            { prop:TestAspect.VALUE_3, amount:2, period:3, maxAmount:10, },
        ];

        var replenishRule:ReplenishRule = new ReplenishRule(cfg);

        makeState(cast [replenishRule], 1, TestBoards.emptyPetri);

        var stateValue1_:AspectPtr = plan.stateAspectLookup[TestAspect.VALUE_1.id];
        var stateValue2_:AspectPtr = plan.stateAspectLookup[TestAspect.VALUE_2.id];
        var stateValue3_:AspectPtr = plan.stateAspectLookup[TestAspect.VALUE_3.id];

        var playerValue1_:AspectPtr = plan.playerAspectLookup[TestAspect.VALUE_1.id];
        var playerValue2_:AspectPtr = plan.playerAspectLookup[TestAspect.VALUE_2.id];
        var playerValue3_:AspectPtr = plan.playerAspectLookup[TestAspect.VALUE_3.id];

        var nodeValue1_:AspectPtr = plan.nodeAspectLookup[TestAspect.VALUE_1.id];
        var nodeValue2_:AspectPtr = plan.nodeAspectLookup[TestAspect.VALUE_2.id];
        var nodeValue3_:AspectPtr = plan.nodeAspectLookup[TestAspect.VALUE_3.id];

        var expectedValues1:Array<Int> = [0,1,2,3,];
        var expectedValues2:Array<Int> = [0,0,0,1,1,1,2,2,2,3,3,3,4,4,4,5,5,5,];
        var expectedValues3:Array<Int> = [0,0,0,2,2,2,4,4,4,6,6,6,8,8,8,10,10,10,];

        for (ike in 0...50) {

            var index1:Int = Std.int(Math.min(expectedValues1.length - 1, ike));
            var index2:Int = Std.int(Math.min(expectedValues2.length - 1, ike));
            var index3:Int = Std.int(Math.min(expectedValues3.length - 1, ike));

            Assert.areEqual(expectedValues1[index1], state.aspects.at(stateValue1_));
            Assert.areEqual(expectedValues2[index2], state.aspects.at(stateValue2_));
            Assert.areEqual(expectedValues3[index3], state.aspects.at(stateValue3_));

            for (player in state.players) {
                Assert.areEqual(expectedValues1[index1], player.at(playerValue1_));
                Assert.areEqual(expectedValues2[index2], player.at(playerValue2_));
                Assert.areEqual(expectedValues3[index3], player.at(playerValue3_));
            }

            for (node in state.nodes) {
                Assert.areEqual(expectedValues1[index1], node.value.at(nodeValue1_));
                Assert.areEqual(expectedValues2[index2], node.value.at(nodeValue2_));
                Assert.areEqual(expectedValues3[index3], node.value.at(nodeValue3_));
            }

            replenishRule.chooseOption(0);
        }
    }
}
