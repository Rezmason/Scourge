package net.rezmason.praxis.config;

import net.rezmason.praxis.rule.*;

using net.rezmason.utils.Alphabetizer;

class GameConfig<RP, MP> {
    
    public var rulePresenters(default, null):Map<String, RP>;
    public var movePresenters(default, null):Map<String, MP>;
    public var actionIDs(default, null):Array<String>;
    public var defaultActionIDs(default, null):Array<String>;
    public var params:Map<String, Dynamic>;

    var modules:Map<String, Module<Dynamic>>;
    var jointRuleDefs:Array<JointRuleDef>;
    
    var ruleIDs:Array<String>;
    var buildersByID:Map<String, Builder<Dynamic>>;
    var actorsByID:Map<String, Actor<Dynamic>>;
    var surveyorsByID:Map<String, Surveyor<Dynamic>>;
    var moduleIDsByRuleID:Map<String, String>;
    var inclusionConditionsByRuleID:Map<String, Dynamic->Bool>;
    var randomConditionsByRuleID:Map<String, Dynamic->Bool>;

    public function makeRules():Map<String, IRule> {
        var rules:Map<String, IRule> = new Map();
        for (ruleID in ruleIDs.iterator().a2z()) {
            var ruleParams = params[moduleIDsByRuleID[ruleID]];
            var inclusionCondition = inclusionConditionsByRuleID[ruleID];
            if (inclusionCondition == null || inclusionCondition(ruleParams)) {
                var randomCondition = randomConditionsByRuleID[ruleID];
                var isRandom = randomCondition != null && randomCondition(ruleParams);
                var builder = buildersByID[ruleID];
                var actor = actorsByID[ruleID];
                var surveyor = surveyorsByID[ruleID];
                rules[ruleID] = new Rule(ruleID, ruleParams, builder, surveyor, actor, isRandom);
            }
        }

        for (def in jointRuleDefs) {
            var sequence = [for (id in def.sequence) if (rules[id] != null) rules[id]];
            if (sequence.length > 0) rules[def.id] = new JointRule(sequence);
        }

        for (id in ['build', 'start', 'forfeit']) if (!rules.exists(id)) throw '"$id" rule not found.';

        return rules;
    }

    function parseModules() {
        params = new Map();
        ruleIDs = [];
        rulePresenters = new Map();
        movePresenters = new Map();
        buildersByID = new Map();
        actorsByID = new Map();
        surveyorsByID = new Map();
        moduleIDsByRuleID = new Map();
        inclusionConditionsByRuleID = new Map();
        randomConditionsByRuleID = new Map();
        actionIDs = [];

        for (moduleKey in modules.keys().a2z()) {
            var module:Module<Dynamic> = modules[moduleKey];
            params[moduleKey] = module.makeDefaultParams();

            var composition = module.composeRules();
            for (compKey in composition.keys().a2z()) {
                var ruleComp = composition[compKey];
                ruleIDs.push(compKey);
                switch (ruleComp.type) {
                    case Builder(builder):
                        buildersByID[compKey] = builder;
                    case Simple(actor, rulePresenter):
                        actorsByID[compKey] = actor;
                        rulePresenters[compKey] = rulePresenter;
                    case Action(builder, surveyor, actor, rulePresenter, movePresenter, isRandom):
                        actionIDs.push(compKey);
                        randomConditionsByRuleID[compKey] = isRandom;
                        actorsByID[compKey] = actor;
                        buildersByID[compKey] = builder;
                        surveyorsByID[compKey] = surveyor;
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
