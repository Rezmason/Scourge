package net.rezmason.scourge.game;

import net.rezmason.praxis.rule.Actor;
import net.rezmason.praxis.rule.Rule;
import net.rezmason.praxis.rule.IRule;

class TestUtils {
    public static function makeRule(actorDef:Class<Actor<Dynamic>>, params:Dynamic):IRule {
        var actor = Type.createInstance(actorDef, []);
        actor.init(params);
        return new Rule(null, null, actor, false);
    }
}
