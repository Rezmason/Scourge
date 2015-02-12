package net.rezmason.ropes.config;

import net.rezmason.ropes.RopesTypes;
import net.rezmason.ropes.JointRule;

using net.rezmason.utils.Alphabetizer;

class GameConfig<RP, MP> {
    
    public var rulePresenters(default, null):Map<String, Class<RP>>;
    public var movePresenters(default, null):Map<String, Class<MP>>;
    public var actionIDs(default, null):Array<String>;
    public var defaultActionIDs(default, null):Array<String>;
    public var params:Map<String, Dynamic>;

    var configDefs:Map<String, Class<Config<Dynamic, RP, MP>>>;
    var jointRuleDefs:Array<JointRuleDef>;
    var fallbackRP:Class<RP>;
    var fallbackMP:Class<MP>;
    
    var rulesByID:Map<String, Class<Rule>>;
    var configIDsByRuleID:Map<String, String>;
    var conditionsByRuleID:Map<String, Dynamic->Bool>;

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

        for (def in jointRuleDefs) {
            var sequence = [for (id in def.sequence) if (rules[id] != null) rules[id]];
            if (sequence.length > 0) {
                var jointRule = new JointRule();
                jointRule.init(sequence);
                rules[def.id] = jointRule;
            }
        }

        return rules;
    }

    function parseConfigDefs() {
        params = new Map();
        rulePresenters = new Map();
        movePresenters = new Map();
        rulesByID = new Map();
        configIDsByRuleID = new Map();
        conditionsByRuleID = new Map();
        actionIDs = [];

        for (configKey in configDefs.keys().a2z()) {
            var config:Config<Dynamic, RP, MP> = Type.createInstance(configDefs[configKey], []);
            params[configKey] = config.defaultParams();

            var composition = config.composition();
            for (compKey in composition.keys().a2z()) {
                var ruleComp = composition[compKey];
                
                rulePresenters[compKey] = (ruleComp.presenter == null) ? fallbackRP : ruleComp.presenter;

                switch (ruleComp.type) {
                    case Action(presenter): 
                        actionIDs.push(compKey);
                        movePresenters[compKey] = (presenter == null) ? fallbackMP : presenter;
                    case _:

                }

                rulesByID[compKey] = ruleComp.def;
                configIDsByRuleID[compKey] = configKey;
                conditionsByRuleID[compKey] = ruleComp.condition;
            }
        }
    }

    function hxSerialize(s:haxe.Serializer):Void {
        var defNames:Map<String, String> = new Map();
        for (key in configDefs.keys()) defNames[key] = Type.getClassName(configDefs[key]);
        s.serialize(defNames);
        s.serialize(jointRuleDefs);
        s.serialize(defaultActionIDs);
        s.serialize(params);
    }

    function hxUnserialize(s:haxe.Unserializer):Void {
        var defNames:Map<String, String> = s.unserialize();
        configDefs = new Map();
        for (key in defNames.keys()) configDefs[key] = cast Type.resolveClass(defNames[key]);
        jointRuleDefs = s.unserialize();
        defaultActionIDs = s.unserialize();
        parseConfigDefs();
        params = s.unserialize();
    }
}
