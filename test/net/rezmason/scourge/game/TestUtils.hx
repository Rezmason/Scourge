package net.rezmason.scourge.game;

import net.rezmason.praxis.rule.BaseRule;

class TestUtils {
    public static function makeRule<Rule:(BaseRule<Dynamic>)>(def:Class<Rule>, params:Dynamic):Rule {
        var rule = Type.createInstance(def, []);
        rule.init(params);
        return rule;
    }
}
