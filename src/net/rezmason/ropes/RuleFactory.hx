package net.rezmason.ropes;

import haxe.ds.ArraySort;
import net.rezmason.ropes.RopesTypes;
import net.rezmason.utils.StringSort;
import net.rezmason.utils.Zig;

using Lambda;
using Type;
using net.rezmason.utils.MapUtils;

class RuleFactory {

    public static function makeBasicRules(ruleDefs:Map<String, Class<Rule>>, cfg:Map<String, Dynamic>):Map<String, Rule> {
        var rules:Map<String, Rule> = new Map();
        if (cfg != null) {
            var cfgKeys:Array<String> = [];
            for (key in cfg.keys()) cfgKeys.push(key);
            ArraySort.sort(cfgKeys, StringSort.sort);
            for (key in cfgKeys) {
                //var ruleDef:Class<Rule> = cast ruleDefs[key].resolveClass();
                var ruleDef:Class<Rule> = ruleDefs[key];
                if (ruleDef == null) {
                    trace('Rule not found: $key');
                } else {
                    rules[key] = ruleDef.createInstance([]);
                    rules[key].init(cfg[key]);
                }
            }
        }
        return rules;
    }

    public static function makeCacheRule(rule:Rule, invalidateSignal:Zig<Int->Void>, revGetter:Void->Int):Rule {
        var cacheRule:CacheRule = new CacheRule();
        cacheRule.init({rule:rule, invalidateSignal:invalidateSignal, revGetter:revGetter});
        return cacheRule;
    }

    public static function combineRules(cfg:Map<String, Array<String>>, basicRules:Map<String, Rule>):Map<String, Rule> {
        var combinedRules:Map<String, Rule> = new Map();

        if (cfg != null) {

            var ruleStack:Array<String> = [];

            function makeJointRule(key:String):Rule {
                ruleStack.push(key);
                var rules:Array<Rule> = [];
                var ruleNames:Array<String> = cfg[key];
                for (ruleName in ruleNames) {
                    if (ruleName == key) trace('Joint rule $key cannot contain itself.');
                    else if (ruleStack.has(ruleName)) trace('Cyclical joint rule definition: $key and $ruleName');
                    else if (basicRules.isNotNull(ruleName)) rules.push(basicRules[ruleName]);
                    else if (combinedRules.isNotNull(ruleName)) rules.push(combinedRules[ruleName]);
                    else if (cfg.isNotNull(ruleName)) rules.push(makeJointRule(ruleName));
                    else trace('Rule not found: $ruleName');
                }
                var jointRule:Rule = new JointRule();
                jointRule.init(rules);
                combinedRules[key] = jointRule;
                ruleStack.pop();
                return jointRule;
            }

            var cfgKeys:Array<String> = [];
            for (key in cfg.keys()) cfgKeys.push(key);

            ArraySort.sort(cfgKeys, StringSort.sort);
            for (key in cfgKeys) {
                if (basicRules.isNotNull(key)) trace('Basic rule already exists with name: $key');
                else if (combinedRules.isNull(key)) makeJointRule(key);
            }
        }

        return combinedRules;
    }
}

/*
    Give each field a status: unbuilt, building, built
    Populate a Map<String, RuleConfigStatus> and check it
*/
