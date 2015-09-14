package net.rezmason.praxis.config;

import net.rezmason.praxis.PraxisTypes;
import net.rezmason.praxis.rule.BaseRule;
import net.rezmason.praxis.rule.JointRule;

using net.rezmason.utils.Alphabetizer;

class GameConfig<RP, MP> {
    
    public var rulePresenters(default, null):Map<String, RP>;
    public var movePresenters(default, null):Map<String, MP>;
    public var actionIDs(default, null):Array<String>;
    public var defaultActionIDs(default, null):Array<String>;
    public var params:Map<String, Dynamic>;

    var modules:Map<String, Module<Dynamic>>;
    var jointRuleDefs:Array<JointRuleDef>;
    
    var rulesByID:Map<String, BaseRule<Dynamic>>;
    var moduleIDsByRuleID:Map<String, String>;
    var inclusionConditionsByRuleID:Map<String, Dynamic->Bool>;
    var randomConditionsByRuleID:Map<String, Dynamic->Bool>;

    public function makeRules(ruleMap:BaseRule<Dynamic>->BaseRule<Dynamic> = null):Map<String, BaseRule<Dynamic>> {
        var rules = new Map();
        for (ruleID in rulesByID.keys().a2z()) {
            var ruleParams = params[moduleIDsByRuleID[ruleID]];
            var inclusionCondition = inclusionConditionsByRuleID[ruleID];
            if (inclusionCondition == null || inclusionCondition(ruleParams)) {
                var randomCondition = randomConditionsByRuleID[ruleID];
                var isRandom = randomCondition != null && randomCondition(ruleParams);
                var rule = rulesByID[ruleID];
                rule.init(ruleParams, isRandom);
                rule.id = ruleID;
                if (ruleMap != null) rule = ruleMap(rule);
                rules[ruleID] = rule;
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

        for (id in ['build', 'start', 'forfeit']) if (!rules.exists(id)) throw '"$id" rule not found.';

        return rules;
    }

    function parseModules() {
        params = new Map();
        rulePresenters = new Map();
        movePresenters = new Map();
        rulesByID = new Map();
        moduleIDsByRuleID = new Map();
        inclusionConditionsByRuleID = new Map();
        randomConditionsByRuleID = new Map();
        actionIDs = [];

        for (moduleKey in modules.keys().a2z()) {
            var module:Module<Dynamic> = modules[moduleKey];
            params[moduleKey] = module.defaultParams;

            var composition = module.composition;
            for (compKey in composition.keys().a2z()) {
                var ruleComp = composition[compKey];
                
                switch (ruleComp.type) {
                    case Builder(rule):
                        rulesByID[compKey] = rule;
                    case Simple(rule, rulePresenter):
                        rulesByID[compKey] = rule;
                        rulePresenters[compKey] = rulePresenter;
                    case Action(rule, rulePresenter, movePresenter, isRandom):
                        actionIDs.push(compKey);
                        randomConditionsByRuleID[compKey] = isRandom;
                        rulesByID[compKey] = rule;
                        rulePresenters[compKey] = rulePresenter;
                        movePresenters[compKey] = movePresenter;
                    case _:

                }

                moduleIDsByRuleID[compKey] = moduleKey;
                inclusionConditionsByRuleID[compKey] = ruleComp.isIncluded;
            }
        }
    }

    function hxSerialize(s:haxe.Serializer):Void {
        s.serialize(modules);
        s.serialize(jointRuleDefs);
        s.serialize(defaultActionIDs);
        s.serialize(params);
    }

    function hxUnserialize(s:haxe.Unserializer):Void {
        modules = s.unserialize();
        jointRuleDefs = s.unserialize();
        defaultActionIDs = s.unserialize();
        parseModules();
        params = s.unserialize();
    }
}
