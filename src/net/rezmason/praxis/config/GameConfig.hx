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
    var moduleIDsByRuleID:Map<String, String>;
    var ruleGeneratorsByID:Map<String, Dynamic->Rule<Dynamic>>;

    public function makeRules():Map<String, IRule> {
        var rules:Map<String, IRule> = new Map();
        for (ruleID in ruleIDs.iterator().a2z()) {
            var rule = ruleGeneratorsByID[ruleID](params[moduleIDsByRuleID[ruleID]]);
            if (rule != null) rules[ruleID] = rule;
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
        moduleIDsByRuleID = new Map();
        ruleGeneratorsByID = new Map();
        actionIDs = [];

        for (moduleKey in modules.keys().a2z()) {
            var module:Module<Dynamic> = modules[moduleKey];
            params[moduleKey] = module.makeDefaultParams();
            var composition = module.composeRules();
            for (ruleID in composition.keys().a2z()) {
                ruleIDs.push(ruleID);
                moduleIDsByRuleID[ruleID] = moduleKey;
                var ruleComp = composition[ruleID];
                var compBuilder = null;
                var compSurveyor = null;
                var compActor = null;
                var compIsRandom = null;
                var compIsIncluded = ruleComp.isIncluded;
                switch (ruleComp.type) {
                    case Builder(builder):
                        compBuilder = builder;
                    case Simple(actor, rulePresenter):
                        compActor = actor;
                        rulePresenters[ruleID] = rulePresenter;
                    case Action(builder, surveyor, actor, rulePresenter, movePresenter, isRandom):
                        actionIDs.push(ruleID);
                        compIsRandom = isRandom;
                        compActor = actor;
                        compBuilder = builder;
                        compSurveyor = surveyor;
                        rulePresenters[ruleID] = rulePresenter;
                        movePresenters[ruleID] = movePresenter;
                    case _:
                }
                var rule = makeRule.bind(ruleID, compBuilder, compSurveyor, compActor, compIsRandom, compIsIncluded);
                ruleGeneratorsByID[ruleID] = rule;
            }
        }
    }

    function makeRule(id, builder, surveyor, actor, isRandom, isIncluded, params) {
        if (isIncluded != null && !isIncluded(params)) return null;
        return new Rule(id, params, builder, surveyor, actor, isRandom != null && isRandom(params));
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
