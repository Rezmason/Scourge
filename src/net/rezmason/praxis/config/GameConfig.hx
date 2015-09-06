package net.rezmason.praxis.config;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.JointRule;

using net.rezmason.utils.Alphabetizer;

class GameConfig<RP, MP> {
    
    public var rulePresenters(default, null):Map<String, Class<RP>>;
    public var movePresenters(default, null):Map<String, Class<MP>>;
    public var actionIDs(default, null):Array<String>;
    public var defaultActionIDs(default, null):Array<String>;
    public var params:Map<String, Dynamic>;
    public var fallbackRP(default, null):Class<RP>;
    public var fallbackMP(default, null):Class<MP>;

    var configDefs:Map<String, Class<Config<Dynamic, RP, MP>>>;
    var jointRuleDefs:Array<JointRuleDef>;
    
    var rulesByID:Map<String, Class<Rule>>;
    var configIDsByRuleID:Map<String, String>;
    var inclusionConditionsByRuleID:Map<String, Dynamic->Bool>;
    var randomConditionsByRuleID:Map<String, Dynamic->Bool>;

    public function makeRules(ruleMap:Rule->Rule = null):Map<String, Rule> {
        var rules = new Map();
        for (ruleID in rulesByID.keys().a2z()) {
            var ruleParams = params[configIDsByRuleID[ruleID]];
            var inclusionCondition = inclusionConditionsByRuleID[ruleID];
            if (inclusionCondition == null || inclusionCondition(ruleParams)) {
                var randomCondition = randomConditionsByRuleID[ruleID];
                var isRandom = randomCondition != null && randomCondition(ruleParams);
                var rule = Type.createInstance(rulesByID[ruleID], [ruleParams, isRandom]);
                if (ruleMap != null) rule = ruleMap(rule);
                rules[ruleID] = rule;
            }
        }

        for (def in jointRuleDefs) {
            var sequence = [for (id in def.sequence) if (rules[id] != null) rules[id]];
            if (sequence.length > 0) rules[def.id] = new JointRule(sequence);
        }

        for (id in ['build', 'start', 'forfeit']) if (!rules.exists(id)) throw '"$id" rule not found.';

        return rules;
    }

    function parseConfigDefs() {
        params = new Map();
        rulePresenters = new Map();
        movePresenters = new Map();
        rulesByID = new Map();
        configIDsByRuleID = new Map();
        inclusionConditionsByRuleID = new Map();
        randomConditionsByRuleID = new Map();
        actionIDs = [];

        for (configKey in configDefs.keys().a2z()) {
            var config:Config<Dynamic, RP, MP> = Type.createInstance(configDefs[configKey], []);
            params[configKey] = config.defaultParams;

            var composition = config.composition;
            for (compKey in composition.keys().a2z()) {
                var ruleComp = composition[compKey];
                
                rulePresenters[compKey] = ruleComp.presenter;

                switch (ruleComp.type) {
                    case Action(presenter): 
                        actionIDs.push(compKey);
                        movePresenters[compKey] = presenter;
                    case _:

                }

                rulesByID[compKey] = ruleComp.def;
                configIDsByRuleID[compKey] = configKey;
                inclusionConditionsByRuleID[compKey] = ruleComp.isIncluded;
                randomConditionsByRuleID[compKey] = ruleComp.isRandom;
            }
        }
    }

    function hxSerialize(s:haxe.Serializer):Void {
        var defNames:Map<String, String> = new Map();
        for (key in configDefs.keys()) defNames[key] = Type.getClassName(configDefs[key]);
        s.serialize(defNames);
        s.serialize(fallbackRP == null ? null : Type.getClassName(fallbackRP));
        s.serialize(fallbackMP == null ? null : Type.getClassName(fallbackMP));
        s.serialize(jointRuleDefs);
        s.serialize(defaultActionIDs);
        s.serialize(params);
    }

    function hxUnserialize(s:haxe.Unserializer):Void {
        var defNames:Map<String, String> = s.unserialize();
        configDefs = new Map();
        for (key in defNames.keys()) configDefs[key] = cast Type.resolveClass(defNames[key]);
        var fallbackRPName = s.unserialize();
        fallbackRP = fallbackRPName == null ? null : cast Type.resolveClass(fallbackRPName);
        var fallbackMPName = s.unserialize();
        fallbackMP = fallbackMPName == null ? null : cast Type.resolveClass(fallbackMPName);
        jointRuleDefs = s.unserialize();
        defaultActionIDs = s.unserialize();
        parseConfigDefs();
        params = s.unserialize();
    }
}
