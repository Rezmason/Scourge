package net.rezmason.scourge.model;

import haxe.macro.Context;
import haxe.macro.Expr;

import net.rezmason.scourge.model.ModelTypes;

using Lambda;
using Type;

class AspectBuilder {

    @:macro public static function build():Array<Field> {

        neko.Lib.print("Building " + Context.getLocalClass().get().name + "  ");

        var pos:Position = Context.currentPos();
        var fields:Array<Field> = Context.getBuildFields();

        for (field in fields) {

            for (metaTag in field.meta) {
                if (metaTag.name == "aspect") {

                    if (field.kind.enumConstructor() != "FVar") {
                        Context.warning(field.name + " must be a variable", field.pos);
                        neko.Lib.print("X");
                        continue;
                    }

                    var aspectExpr:Expr = metaTag.params[0];

                    switch (aspectExpr.expr) {
                        case EConst(c): switch (c) {
                            case CIdent(s):
                                aspectExpr = Context.parse("Aspect." + s, field.pos);
                            default:
                        }
                        default:
                    }

                    metaTag.params = [];
                    var expr:Expr = macro {id:Aspect.ids++, initialValue:$aspectExpr};

                    field.access = [AStatic, APublic];
                    field.kind = FVar(null, {pos:field.pos, expr:expr.expr});

                    neko.Lib.print(metaTag.name.charAt(0));

                    break;
                }
            }
        }

        neko.Lib.print("\n");

        return fields;
    }
}

