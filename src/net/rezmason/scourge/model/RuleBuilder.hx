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
        //reqs.set("requireExtra", "extraAspectRequirements");
        reqs;
    }

    private static var lookupTablesByMetaTag:Hash<String> = {
        var tables:Hash<String> = new Hash<String>();
        tables.set("requireState", "stateAspectLookup");
        tables.set("requirePlayer", "playerAspectLookup");
        tables.set("requireNode", "nodeAspectLookup");
        //tables.set("requireExtra", "extraAspectLookup");
        tables;
    }

    private static var restrictedFields:Array<String> = [
        "__initReqs",
        "__initPointers",
    ];

    @:macro public static function build() : Array<Field> {
        var pos:Position = Context.currentPos();
        var fields:Array<Field> = Context.getBuildFields();

        var reqExpressions:Array<Expr> = [];
        var ptrExpressions:Array<Expr> = [];

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

                    var reqExpr:Expr = {expr: ECall({expr: EField({expr: EConst(CIdent(reqName)), pos: pos }, "push"), pos: pos},[{expr: EField({expr: EConst(CIdent(aspectCategory)), pos: pos}, aspectName), pos: pos}]), pos: pos};

                    reqExpressions.push(reqExpr);

                    // field = plan.stateAspectLookup[Aspect.ASPECT.id];

                    var ptrExpr:Expr = {expr: EBinop(OpAssign,{expr: EConst(CIdent(ptrName)), pos: pos },{expr: EArray({expr: EField({expr: EConst(CIdent("plan")), pos: pos }, lookupName), pos: pos},{expr: EField({expr:EField({expr: EConst(CIdent(aspectCategory)), pos: pos }, aspectName),pos: pos}, "id"),pos: pos}),pos: pos}),pos: pos};

                    ptrExpressions.push(ptrExpr);

                    break;
                }
            }
        }

        fields.push(makePrivateFuncField("__initReqs", Context.currentPos(), reqExpressions));
        fields.push(makePrivateFuncField("__initPtrs", Context.currentPos(), ptrExpressions));

        return fields;
    }

    private static function makePrivateFuncField(name:String, pos:Position, expressions:Array<Expr>):Field {
        var func:Function = {params:[], args:[], ret:null, expr:{pos:pos, expr: EBlock(expressions)}};
        return { name:name, doc:null, meta:[], access:[APrivate, AOverride], kind:FFun(func), pos:pos };
    }
}

