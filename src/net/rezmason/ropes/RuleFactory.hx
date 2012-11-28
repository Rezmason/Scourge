package net.rezmason.ropes;

import net.rezmason.ropes.ModelTypes;

using Lambda;
using Reflect;
using Type;

class RuleFactory {

    public static function makeBasicRules(ruleDefs:Hash<Class<Rule>>, cfg:Dynamic):Hash<Rule> {

        var rules:Hash<Rule> = new Hash<Rule>();

        if (cfg != null) {
            for (field in cfg.fields()) {
                //var ruleDef:Class<Rule> = cast ruleDefs.get(field).resolveClass();
                var ruleDef:Class<Rule> = ruleDefs.get(field);
                if (ruleDef == null) {
                    trace("Rule not found: " + field);
                } else {
                    var args:Array<Dynamic> = [cfg.field(field)];
                    args.remove(null);
                    rules.set(field, ruleDef.createInstance(args));
                }
            }
        }
        return rules;
    }

    public static function combineRules(cfg:Dynamic<Array<String>>, basicRules:Hash<Rule>):Hash<Rule> {
        var combinedRules:Hash<Rule> = new Hash<Rule>();
        if (cfg != null) {

            function makeJointRule(field:String):JointRule {
                var rules:Array<Rule> = [];
                var ruleFields:Array<String> = cfg.field(field);
                for (ruleField in ruleFields) {
                    if (ruleField == field) trace("Joint rules cannot contain themselves.");
                    else if (basicRules.exists(ruleField)) rules.push(basicRules.get(ruleField));
                    else if (combinedRules.exists(ruleField)) rules.push(combinedRules.get(ruleField));
                    else if (cfg.hasField(ruleField)) rules.push(makeJointRule(ruleField));
                    else trace("Rule not found: " + ruleField);
                }
                var jointRule:JointRule = new JointRule(rules);
                combinedRules.set(field, jointRule);
                return jointRule;
            }

            for (field in cfg.fields()) {
                if (basicRules.exists(field)) trace("Basic rule already exists with name: " + field);
                else if (!combinedRules.exists(field)) makeJointRule(field);
            }
        }
        return combinedRules;
    }
}
