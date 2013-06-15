package net.rezmason.ropes;

import haxe.ds.ArraySort;
import net.rezmason.ropes.Types;
import net.rezmason.utils.StringSort;

using Lambda;
using Reflect;
using Type;

class RuleFactory {

    public static function makeBasicRules(ruleDefs:Map<String, Class<Rule>>, cfg:Dynamic):Map<String, Rule> {

        var rules:Map<String, Rule> = new Map<String, Rule>();

        if (cfg != null) {
            var cfgFields:Array<String> = cfg.fields();
            ArraySort.sort(cfgFields, StringSort.sort);
            for (field in cfgFields) {
                //var ruleDef:Class<Rule> = cast ruleDefs[field].resolveClass();
                var ruleDef:Class<Rule> = ruleDefs[field];
                if (ruleDef == null) {
                    trace('Rule not found: $field');
                } else {
                    var args:Array<Dynamic> = [cfg.field(field)];
                    args.remove(null);
                    rules[field] = ruleDef.createInstance(args);
                }
            }
        }
        return rules;
    }

    public static function combineRules(cfg:Dynamic<Array<String>>, basicRules:Map<String, Rule>):Map<String, Rule> {
        var combinedRules:Map<String, Rule> = new Map<String, Rule>();

        if (cfg != null) {

            var ruleStack:Array<String> = [];

            function makeJointRule(field:String):Rule {
                ruleStack.push(field);
                var rules:Array<Rule> = [];
                var ruleFields:Array<String> = cfg.field(field);
                for (ruleField in ruleFields) {
                    if (ruleField == field) trace('Joint rule $field cannot contain itself.');
                    else if (ruleStack.has(ruleField)) trace('Cyclical joint rule definition: $field and $ruleField');
                    else if (basicRules.exists(ruleField)) rules.push(basicRules[ruleField]);
                    else if (combinedRules.exists(ruleField)) rules.push(combinedRules[ruleField]);
                    else if (cfg.hasField(ruleField)) rules.push(makeJointRule(ruleField));
                    else trace('Rule not found: $ruleField');
                }
                var jointRule:Rule = new JointRule(rules);
                combinedRules[field] = jointRule;
                ruleStack.pop();
                return jointRule;
            }

            var cfgFields:Array<String> = cfg.fields();
            ArraySort.sort(cfgFields, StringSort.sort);
            for (field in cfgFields) {
                if (basicRules.exists(field)) trace('Basic rule already exists with name: $field');
                else if (!combinedRules.exists(field)) makeJointRule(field);
            }
        }
        return combinedRules;
    }
}

/*
    Give each field a status: unbuilt, building, built
    Populate a Map<String, RuleConfigStatus> and check it
*/
