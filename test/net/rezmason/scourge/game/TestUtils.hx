package net.rezmason.scourge.game;

import net.rezmason.praxis.PraxisTypes;

class TestUtils {
    public static function makeRule<R:(Rule)>(def:Class<R>, params:Dynamic):R {
        var rule = Type.createInstance(def, []);
        rule.init(params);
        return rule;
    }
}
