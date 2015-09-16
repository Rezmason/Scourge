package net.rezmason.scourge.game;

import net.rezmason.praxis.rule.*;

class TestUtils {
    public static function makeRule(
        ?builderDef:Class<Builder<Dynamic>>, 
        ?surveyorDef:Class<Surveyor<Dynamic>>, 
        ?actorDef:Class<Actor<Dynamic>>, 
        params:Dynamic
    ):IRule {

        var builder:Builder<Dynamic> = null;
        if (builderDef != null) {
            builder = Type.createInstance(builderDef, []);
            builder.init(params);
        }

        var surveyor:Surveyor<Dynamic> = null;
        if (surveyorDef != null) {
            surveyor = Type.createInstance(surveyorDef, []);
            surveyor.init(params);
        }

        var actor:Actor<Dynamic> = null;
        if (actorDef != null) {
            actor = Type.createInstance(actorDef, []);
            actor.init(params);
        }

        return new Rule(null, builder, surveyor, actor, false);
    }
}
