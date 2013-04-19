package net.rezmason.ropes;

import haxe.ds.ArraySort;
import haxe.ds.StringMap;
import net.rezmason.ropes.Types;
import net.rezmason.utils.StringSort;

using Lambda;
using Reflect;
using Type;

class RuleFactory {

    public static function makeBasicRules(ruleDefs:StringMap<Class<Rule>>, cfg:Dynamic):StringMap<Rule> {

        var rules:StringMap<Rule> = new StringMap<Rule>();

        if (cfg != null) {
            var cfgFields:Array<String> = cfg.fields();
            ArraySort.sort(cfgFields, StringSort.sort);
            for (field in cfgFields) {
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

    public static function combineRules(cfg:Dynamic<Array<String>>, basicRules:StringMap<Rule>):StringMap<Rule> {
        var combinedRules:StringMap<Rule> = new StringMap<Rule>();

        if (cfg != null) {

            var ruleStack:Array<String> = [];

            function makeJointRule(field:String):JointRule {
                ruleStack.push(field);
                var rules:Array<Rule> = [];
                var ruleFields:Array<String> = cfg.field(field);
                for (ruleField in ruleFields) {
                    if (ruleField == field) trace("Joint rule " + field + " cannot contain itself.");
                    else if (ruleStack.has(ruleField)) trace("Cyclical joint rule definition: " + field + " and " + ruleField);
                    else if (basicRules.exists(ruleField)) rules.push(basicRules.get(ruleField));
                    else if (combinedRules.exists(ruleField)) rules.push(combinedRules.get(ruleField));
                    else if (cfg.hasField(ruleField)) rules.push(makeJointRule(ruleField));
                    else trace("Rule not found: " + ruleField);
                }
                var jointRule:JointRule = new JointRule(rules);
                combinedRules.set(field, jointRule);
                ruleStack.pop();
                return jointRule;
            }

            var cfgFields:Array<String> = cfg.fields();
            ArraySort.sort(cfgFields, StringSort.sort);
            for (field in cfgFields) {
                if (basicRules.exists(field)) trace("Basic rule already exists with name: " + field);
                else if (!combinedRules.exists(field)) makeJointRule(field);
            }
        }
        return combinedRules;
    }
}

/*
    Give each field a status: unbuilt, building, built
    Populate a StringMap<RuleConfigStatus> and check it
*/
