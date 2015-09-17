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
        if (builderDef != null) builder = Type.createInstance(builderDef, []);

        var surveyor:Surveyor<Dynamic> = null;
        if (surveyorDef != null) surveyor = Type.createInstance(surveyorDef, []);

        var actor:Actor<Dynamic> = null;
        if (actorDef != null) actor = Type.createInstance(actorDef, []);

        return new Rule(null, params, builder, surveyor, actor, false);
    }
}
