package net.rezmason.scourge.model;

import net.rezmason.scourge.model.ModelTypes;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
#end

typedef RuleDef = Class<Rule>;

using Lambda;
using Reflect;
using Type;

class RuleFactory {

    private static var ruleDefs:Hash<RuleDef>;
    //*
    @:macro private static function getRuleDefs() {
        var pos:Position = Context.currentPos();

        var posString:String = Context.getPosInfos(pos).file;
        var path:String = posString.substr(0, posString.lastIndexOf("/") + 1);
        var pkg:String = ~/(\/)/g.replace(path, ".");
        var srcIndex:Int = pkg.indexOf("src.");
        if (srcIndex == 0) pkg = pkg.substr(srcIndex + "src.".length);

        var decExpr:Expr = macro var hash:Hash<RuleDef> = new Hash<RuleDef>();
        var retExpr:Expr = macro hash;

        var setExprs:Array<Expr> = [];

        var files:Array<String> = FileSystem.readDirectory(path + "rules");
        pkg += "rules.";
        for (file in files) {
            var clazz:String = file;
            var hxIndex:Int = clazz.indexOf(".hx");
            if (hxIndex == -1) continue;
            clazz = clazz.substring(0, hxIndex);

            var ruleIndex:Int = clazz.indexOf("Rule");
            var key:String = clazz;
            if (ruleIndex == -1) continue;
            key = clazz.substring(0, ruleIndex);
            key = key.charAt(0).toLowerCase() + key.substr(1);

            var inf = {min:setExprs.length, max:setExprs.length, file:pkg + clazz};
            var clazzDef:Expr = Context.parse(pkg + clazz, Context.makePosition(inf));
            //trace(clazzDef); // EField(EField(EField(EConst(CIdent("path")), "to"), "my"), "Class")

            var expr:Expr = macro hash.set($(key), cast $clazzDef );
            setExprs.push(expr);
        }

        var block:Array<Expr> = [decExpr].concat(setExprs).concat([retExpr]);

        return {expr:EBlock(block), pos:pos};
    }
    /**/

    //private static function getRuleDefs() return null;

    public static function makeBasicRules(cfg:Dynamic):Hash<Rule> {

        if (ruleDefs == null) ruleDefs = getRuleDefs();

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
