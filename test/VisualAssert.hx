package;

class VisualAssert {

    public static function assert(message:String, string:String, force:Bool = false) {
        #if !VISUAL_TEST if (!force) return; #end
        trace(message);
        trace(string);
    }
}
