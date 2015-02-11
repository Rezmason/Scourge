package net.rezmason.scourge.model;

import net.rezmason.ropes.RopesTypes;

using net.rezmason.utils.Alphabetizer;

class GameConfig<RP, MP> {
    
    var params(default, null):Map<String, Dynamic>;
    var configs(default, null):Map<String, Config<Dynamic, RP, MP>>;
    var rulePresenters(default, null):Map<String, Class<RP>>;
    var movePresenters(default, null):Map<String, Class<MP>>;
    var builderRules(default, null):Array<Class<Rule>>;
    var rules(default, null):Array<Class<Rule>>;
    var rulesByID(default, null):Map<String, Class<Rule>>;
    var configIDsByRuleID(default, null):Map<String, String>;
    var conditionsByRuleID(default, null):Map<String, Dynamic->Bool>;

    var fallbackRP:Class<RP>;
    var fallbackMP:Class<MP>;
    var defs:Map<String, Class<Config<Dynamic, RP, MP>>>;

    public function new(defs:Map<String, Class<Config<Dynamic, RP, MP>>>) {
        this.defs = defs;
        parseDefs();
    }

    public function makeRules(ruleMap:Rule->Rule = null):Map<String, Rule> {
        var rules = new Map();
        for (key in rulesByID.keys().a2z()) {
            var ruleParams = params[configIDsByRuleID[key]];
            if (conditionsByRuleID[key] == null || conditionsByRuleID[key](ruleParams)) {
                var rule = Type.createInstance(rulesByID[key], []);
                rule.init(ruleParams);
                if (ruleMap != null) rule = ruleMap(rule);
                rules[key] = rule;
            }
        }
        return rules;
    }

    function parseDefs() {
        params = new Map();
        configs = new Map();
        rulePresenters = new Map();
        movePresenters = new Map();
        builderRules = [];
        rules = [];
        rulesByID = new Map();
        configIDsByRuleID = new Map();
        conditionsByRuleID = new Map();

        for (configKey in defs.keys().a2z()) {
            var config:Config<Dynamic, RP, MP> = Type.createInstance(defs[configKey], []);
            configs[configKey] = config;
            params[configKey] = config.defaultParams();

            var composition = config.composition();
            for (compKey in composition.keys().a2z()) {
                var ruleComp = composition[compKey];
                
                rulePresenters[compKey] = (ruleComp.presenter == null) ? fallbackRP : ruleComp.presenter;

                switch (ruleComp.type) {
                    case Simple: 
                    case Action(presenter): movePresenters[compKey] = (presenter == null) ? fallbackMP : presenter;
                    case Builder: builderRules.push(ruleComp.def);
                }

                rules.push(ruleComp.def);
                rulesByID[compKey] = ruleComp.def;
                configIDsByRuleID[compKey] = configKey;
                conditionsByRuleID[compKey] = ruleComp.condition;
            }
        }
    }

    function hxSerialize(s:haxe.Serializer):Void {
        var defNames:Map<String, String> = new Map();
        for (key in defs.keys()) defNames[key] = Type.getClassName(defs[key]);
        s.serialize(defNames);
        s.serialize(params);
    }

    function hxUnserialize(s:haxe.Unserializer):Void {
        var defNames:Map<String, String> = s.unserialize();
        defs = new Map();
        for (key in defNames.keys()) defs[key] = cast Type.resolveClass(defNames[key]);
        parseDefs();
        params = s.unserialize();
    }
}
