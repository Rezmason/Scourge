package;

class VisualAssert {

    public static function assert(message:String, string:String) {
        #if VISUAL_TEST
            trace(message);
            trace(string);
        #end
    }
}
