package net.rezmason.ropes;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import net.rezmason.ropes.Types;
#end

#if !macro @:autoBuild(net.rezmason.ropes.Aspect.build()) #end class Aspect {
    private static var ids:Int = 0;
    public inline static var TRUE:Int = 1;
    public inline static var FALSE:Int = 0;
    public inline static var NULL:Int = -1;

    @:macro public static function build():Array<Field> {

        var msg:String = "Building " + Context.getLocalClass().get().name + "  ";

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

                    metaTag.params = [];
                    var expr:Expr = macro {id:Aspect.ids++, initialValue:$aspectExpr};

                    field.access = [AStatic, APublic];
                    field.kind = FVar(null, {pos:field.pos, expr:expr.expr});

                    msg += metaTag.name.charAt(0);

                    break;
                }
            }
        }

        msg += "\n";

        #if SCOURGE_VERBOSE
            neko.Lib.print(msg);
        #end

        return fields;
    }
}
