package net.rezmason.utils;

typedef Pointer<T> = #if USE_POINTERS { var addr(default, null):Int; } #else Int #end ;

class Pointers {
    public inline static function d<T>(pointer:Pointer<T>, array:Array<T>):T {
        return array[#if USE_POINTERS pointer.addr #else pointer #end];
    }

    public inline static function addr<T>(array:Array<T>, index:Int):Pointer<T> {
        return #if USE_POINTERS {addr:index} #else index #end;
    }
}
