package net.rezmason.ropes;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import net.rezmason.ropes.RopesTypes;
#end

#if !macro @:autoBuild(net.rezmason.ropes.Aspect.build()) #end class Aspect {
    public inline static var TRUE:Int = 1;
    public inline static var FALSE:Int = 0;
    public inline static var NULL:Int = -1;

    macro public static function build():Array<Field> {

        var classType = Context.getLocalClass().get();

        var msg:String = 'Aspect processing ${classType.name}  ';

        var pos:Position = Context.currentPos();
        var fields:Array<Field> = Context.getBuildFields();

        for (field in fields) {

            for (metaTag in field.meta) {
                if (metaTag.name == 'aspect') {

                    var aspect:Expr = metaTag.params[0];
                    metaTag.params = [];

                    // Turn some literal values into Aspect consts
                    switch (aspect.expr) {
                        case EConst(CIdent(s)):
                            aspect = macro $p{['Aspect', s.toUpperCase()]};
                        case _:
                    }

                    var id:Expr = macro $v{classType.module + '::' + field.name.toUpperCase()};
                    field.access = [AStatic, APublic];
                    field.kind = FVar(null, macro {id:$id, initialValue:$aspect});

                    msg += metaTag.name.charAt(0);

                    break;
                }
            }
        }

        msg += '\n';

        #if ROPES_MACRO_VERBOSE
            Sys.print(msg);
        #end

        return fields;
    }
}
