package net.rezmason.scourge.tools;

#if openfl
import openfl.Assets;
#end

class Resource {
    public inline static function getString(path:String):String {
        return #if openfl Assets.getText #else haxe.Resource.getString #end (path);
    }
}
