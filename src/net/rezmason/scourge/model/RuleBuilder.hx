package net.rezmason.scourge.model;

import haxe.macro.Context;
import haxe.macro.Expr;

import net.rezmason.scourge.model.ModelTypes;

using Lambda;
using StringTools;
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

        var notes:Array<Array<String>> = [];

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

                    var aspectExpr:Expr = metaTag.params[0];
                    metaTag.params = [];

                    var aspectCategory:String;
                    var aspectName:String;
                    var ptrName:String = field.name;
                    var reqName:String = reqsByMetaTag.get(metaTag.name);
                    var lookupName:String = lookupTablesByMetaTag.get(metaTag.name);

                    // EField({expr:EConst(CIdent(aspectCategory)), pos:pos}, aspectName)

                    try {
                        var aspectParams = aspectExpr.expr.enumParameters();
                        var category:Expr = aspectParams[0];
                        var categoryIdent:Constant = category.expr.enumParameters()[0];
                        var categoryParams = categoryIdent.enumParameters();

                        aspectCategory = categoryParams[0];
                        aspectName = aspectParams[1];
                    } catch (whatever:Dynamic) {
                        throw new Error("invalid AspectProperty " + aspectExpr, field.pos);
                    }

                    notes.push([field.name, aspectCategory, aspectName, metaTag.name.substr("require".length)]);

                    // preqs.push(Aspect.ASPECT)
                    var reqExpr:Expr = call(constant(reqName), "push", [aspectExpr]);

                    // plan | this
                    var lookupExpr:Expr = constant(metaTag.name == "requireExtra" ? "this" : "plan");

                    // field = plan.stateAspectLookup[Aspect.ASPECT.id];
                    var ptrExpr:Expr = assign(constant(ptrName), arrayLookup(prop(lookupExpr, lookupName), prop(aspectExpr, "id")));

                    reqExpressions.push(reqExpr);
                    ptrExpressions.push(ptrExpr);

                    break;
                }
            }
        }

        if (notes.length > 0) printCaption(Context.getLocalClass().get().module, notes);

        fields.push(overrider("__initReqs", reqExpressions));
        fields.push(overrider("__initPtrs", ptrExpressions));

        return fields;
    }

    private static function printCaption(module:String, notes:Array<Array<String>>):Void {
        neko.Lib.println("Building " + module);
        var column1:Int = 0;
        var column2:Int = 0;
        var column3:Int = 0;

        for (note in notes) {
            if (column1 < note[0].length) column1 = note[0].length;
            if (column2 < note[1].length + note[2].length + 1) column2 = note[1].length + note[2].length + 1;
            if (column3 < note[3].length) column3 = note[3].length;
        }

        for (note in notes) {
            var str:String = "|\t" +
                note.shift().rpad(" ", column1 + 2) +
                (note.shift() + "." + note.shift()).rpad(" ", column2 + 2) +
                note.shift().lpad(" ", column3);

            neko.Lib.println(str);
        }

        neko.Lib.println("");
    }
}

