package net.rezmason.scourge.model;

import haxe.macro.Context;
import haxe.macro.Expr;

using Lambda;

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

        var msg:String = "Building " + Context.getLocalClass().get().name + "  ";

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

                    field.access.remove(AStatic);

                    var reqs:Expr = Context.parse(metaTag.name + "AspectRequirements", pos);
                    var ptr:Expr = Context.parse(field.name, pos);
                    var lkp:Expr = Context.parse(lkpSources.get(metaTag.name) + "." + metaTag.name + "AspectLookup", pos);

                    reqExpressions.push( macro $reqs.push($aspectExpr) );
                    ptrExpressions.push( macro $ptr = $lkp[$aspectExpr.id] );

                    //neko.Lib.println(macro :net.rezmason.scourge.model.ModelTypes.AspectPtr);

                    field.kind = FVar(macro :net.rezmason.scourge.model.ModelTypes.AspectPtr, null);

                    msg += metaTag.name.charAt(0);

                    break;
                }
            }
        }

        msg += "\n";

        fields.push(overrider("__initReqs", reqExpressions, pos));
        fields.push(overrider("__initPtrs", ptrExpressions, pos));

        #if SCOURGE_VERBOSE
            neko.Lib.print(msg);
        #end

        return fields;
    }

    private inline static function overrider(name:String, expressions:Array<Expr>, pos:Position):Field {
        var func:Function = {params:[], args:[], ret:null, expr:{pos:pos, expr:EBlock(expressions)}};
        return { name:name, access:[APrivate, AOverride], kind:FFun(func), pos:pos };
    }
}

