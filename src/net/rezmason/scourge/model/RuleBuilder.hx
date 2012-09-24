package net.rezmason.scourge.model;

import haxe.macro.Context;
import haxe.macro.Expr;

import net.rezmason.scourge.model.ModelTypes;

using Lambda;
using Type;

class RuleBuilder {

    private static var reqsByMetaTag:Hash<String> = {
        var reqs:Hash<String> = new Hash<String>();
        reqs.set("requireState", "stateAspectRequirements");
        reqs.set("requirePlayer", "playerAspectRequirements");
        reqs.set("requireNode", "nodeAspectRequirements");
        reqs.set("requireExtra", "extraAspectRequirements");
        reqs;
    }

    private static var lookupTablesByMetaTag:Hash<String> = {
        var tables:Hash<String> = new Hash<String>();
        tables.set("requireState", "stateAspectLookup");
        tables.set("requirePlayer", "playerAspectLookup");
        tables.set("requireNode", "nodeAspectLookup");
        tables.set("requireExtra", "extraAspectLookup");
        tables;
    }

    private static var restrictedFields:Array<String> = [
        "__initReqs",
        "__initPointers",
    ];

    @:macro public static function build():Array<Field> {
        var pos:Position = Context.currentPos();
        var fields:Array<Field> = Context.getBuildFields();

        var reqExpressions:Array<Expr> = [];
        var ptrExpressions:Array<Expr> = [];

        inline function overrider(name:String, expressions:Array<Expr>):Field {
            var func:Function = {params:[], args:[], ret:null, expr:{pos:pos, expr:EBlock(expressions)}};
            return { name:name, doc:null, meta:[], access:[APrivate, AOverride], kind:FFun(func), pos:pos };
        }

        inline function constant(name:String):Expr { return { expr:EConst( CIdent( name ) ), pos:pos }; }

        inline function prop(obj:Expr, name:String):Expr { return { expr:EField(obj, name), pos:pos}; }

        inline function call(obj:Expr, name:String, args:Array<Expr>):Expr { return { expr:ECall(prop(obj, name), args), pos:pos}; }

        inline function arrayLookup(obj:Expr, index:Expr):Expr { return { expr:EArray(obj, index), pos:pos}; }

        inline function assign(left:Expr, right:Expr):Expr { return { expr:EBinop(OpAssign, left, right), pos:pos}; }

        for (field in fields) {

            if (restrictedFields.has(field.name)) {
                throw new Error("Rules cannot manually override the function " + field.name, field.pos);
            }

            for (metaTag in field.meta) {

                if (reqsByMetaTag.exists(metaTag.name)) {

                    var aspect = metaTag.params[0];
                    metaTag.params = [];

                    var aspectCategory:String;
                    var aspectName:String;
                    var ptrName:String = field.name;
                    var reqName:String = reqsByMetaTag.get(metaTag.name);
                    var lookupName:String = lookupTablesByMetaTag.get(metaTag.name);

                    // EField({expr:EConst(CIdent(aspectCategory)), pos:pos}, aspectName)

                    try {
                        var aspectParams = aspect.expr.enumParameters();
                        var category:Expr = aspectParams[0];
                        var categoryIdent:Constant = category.expr.enumParameters()[0];
                        var categoryParams = categoryIdent.enumParameters();

                        aspectCategory = categoryParams[0];
                        aspectName = aspectParams[1];
                    } catch (whatever:Dynamic) {
                        throw new Error("invalid Aspect " + aspect, field.pos);
                    }

                    neko.Lib.println([aspectCategory, aspectName, ptrName, reqName, lookupName]);

                    // reqs.push(Aspect.ASPECT)

                    var aspectExpr:Expr = prop(constant(aspectCategory), aspectName);
                    var reqExpr:Expr = call(constant(reqName), "push", [aspectExpr]);

                    reqExpressions.push(reqExpr);

                    // field = plan.stateAspectLookup[Aspect.ASPECT.id];

                    var lookupExpr:Expr = prop(constant("plan"), lookupName);
                    if (metaTag.name == "requireExtra") lookupExpr = constant(lookupName);

                    var ptrExpr:Expr = assign(constant(ptrName), arrayLookup(lookupExpr, prop(aspectExpr, "id")));

                    ptrExpressions.push(ptrExpr);

                    break;
                }
            }
        }

        fields.push(overrider("__initReqs", reqExpressions));
        fields.push(overrider("__initPtrs", ptrExpressions));

        return fields;
    }
}

