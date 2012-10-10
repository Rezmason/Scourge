package net.rezmason.scourge.model;

import haxe.macro.Context;
import haxe.macro.Expr;

import net.rezmason.scourge.model.ModelTypes;

using Lambda;
using Type;

class RuleBuilder {

    private static var lkpSources:Hash<String> = {
        var hash:Hash<String> = new Hash<String>();
        hash.set("state",  "plan");
        hash.set("player", "plan");
        hash.set("node",   "plan");
        hash.set("extra",  "this");
        hash;
    }

    private static var restrictedFields:Array<String> = [ "__initReqs", "__initPointers", ];

    @:macro public static function build():Array<Field> {

        neko.Lib.print("Building " + Context.getLocalClass().get().name + "  ");

        var pos:Position = Context.currentPos();
        var fields:Array<Field> = Context.getBuildFields();

        var reqExpressions:Array<Expr> = [];
        var ptrExpressions:Array<Expr> = [];

        for (field in fields) {

            if (restrictedFields.has(field.name)) {
                throw new Error("Rules cannot manually override the function " + field.name, field.pos);
            }

            for (metaTag in field.meta) {
                if (lkpSources.exists(metaTag.name)) {

                    var aspectExpr:Expr = metaTag.params[0];
                    metaTag.params = [];

                    /*
                    if (Context.typeof(aspectExpr).enumParameters()[0].get().name != "AspectProperty") {
                        Context.warning("Value assigned to " + field.name + " is not an AspectProperty", aspectExpr.pos);
                        neko.Lib.print("X");
                        continue;
                    }
                    */

                    if (field.access.has(AStatic)) {
                        Context.warning(field.name + " cannot be static", field.pos);
                        neko.Lib.print("X");
                        continue;
                    }

                    if (field.kind.enumConstructor() != "FVar") {
                        Context.warning(field.name + " must be a variable", field.pos);
                        neko.Lib.print("X");
                        continue;
                    }

                    var reqs:Expr = Context.parse(metaTag.name + "AspectRequirements", pos);
                    var ptr:Expr = Context.parse(field.name, pos);
                    var lkp:Expr = Context.parse(lkpSources.get(metaTag.name) + "." + metaTag.name + "AspectLookup", pos);

                    reqExpressions.push( macro $reqs.push($aspectExpr) );
                    ptrExpressions.push( macro $ptr = $lkp[$aspectExpr.id] );

                    neko.Lib.print(metaTag.name.charAt(0));

                    break;
                }
            }
        }

        neko.Lib.print("\n");

        fields.push(overrider("__initReqs", reqExpressions, pos));
        fields.push(overrider("__initPtrs", ptrExpressions, pos));

        return fields;
    }

    private inline static function overrider(name:String, expressions:Array<Expr>, pos:Position):Field {
        var func:Function = {params:[], args:[], ret:null, expr:{pos:pos, expr:EBlock(expressions)}};
        return { name:name, access:[APrivate, AOverride], kind:FFun(func), pos:pos };
    }
}

