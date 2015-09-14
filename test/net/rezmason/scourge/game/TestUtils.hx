package net.rezmason.scourge.game;

import net.rezmason.praxis.rule.BaseRule;

class TestUtils {
    public static function makeRule<Params, R:(BaseRule<Params>)>(def:Class<R>, params:Params):R {
        var rule = Type.createInstance(def, []);
        rule.init(params);
        return rule;
    }
}
