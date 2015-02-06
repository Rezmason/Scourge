package net.rezmason.scourge.model.meta;

import net.rezmason.scourge.model.bite.BiteAspect;
import net.rezmason.scourge.model.piece.SwapAspect;

class MetaConfig extends Config<MetaParams> {

    override public function id():String {
        return 'meta';
    }

    public override function ruleComposition():RuleComposition {
        return null;
    }

    override public function defaultParams():Null<MetaParams> {
        return {
            maxSkips: 3,
            playerProperties: [],
            nodeProperties: [],
            globalProperties: [
                { prop:SwapAspect.NUM_SWAPS, amount:1, period:4, maxAmount:10, },
                { prop:BiteAspect.NUM_BITES, amount:1, period:3, maxAmount:10, },
            ]
        };
    }
}
