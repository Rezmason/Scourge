package net.rezmason.ropes;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import net.rezmason.ropes.Types;
#end

#if !macro @:autoBuild(net.rezmason.ropes.Aspect.build()) #end class Aspect {
    public inline static var TRUE:Int = 1;
    public inline static var FALSE:Int = 0;
    public inline static var NULL:Int = -1;

    @:macro public static function build():Array<Field> {

        var classType = Context.getLocalClass().get();

        var msg:String = "Building " + classType.name + "  ";

        var pos:Position = Context.currentPos();
        var fields:Array<Field> = Context.getBuildFields();

        for (field in fields) {

            for (metaTag in field.meta) {
                if (metaTag.name == "aspect") {

                    var aspectExpr:Expr = metaTag.params[0];

                    // Turn some literal values into Aspect consts
                    switch (aspectExpr.expr) {
                        case EConst(c):
                            switch (c) {
                                case CIdent(s):
                                    aspectExpr = Context.parse("Aspect." + s.toUpperCase(), field.pos);
                                default:
                            }
                        default:
                    }

                    var idConst = EConst(CString(classType.module + "::" + field.name.toUpperCase()));
                    var idExpr:Expr = {expr:idConst, pos:pos};

                    metaTag.params = [];
                    var expr:Expr = macro {id:$idExpr, initialValue:$aspectExpr};

                    field.access = [AStatic, APublic];
                    field.kind = FVar(null, {pos:field.pos, expr:expr.expr});

                    msg += metaTag.name.charAt(0);

                    break;
                }
            }
        }

        msg += "\n";

        #if ROPES_VERBOSE
            neko.Lib.print(msg);
        #end

        return fields;
    }
}
