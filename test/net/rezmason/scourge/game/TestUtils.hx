package net.rezmason.scourge.game;

import net.rezmason.praxis.rule.*;

class TestUtils {
    public static function makeRule(surveyorDef:Class<Surveyor<Dynamic>>, actorDef:Class<Actor<Dynamic>>, params:Dynamic):IRule {
        var actor = Type.createInstance(actorDef, []);
        actor.init(params);
        var surveyor = null;
        if (surveyorDef != null) {
            surveyor = Type.createInstance(surveyorDef, []);
            surveyor.init(params);
        }
        return new Rule(null, surveyor, actor, false);
    }
}
