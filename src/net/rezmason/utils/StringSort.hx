package net.rezmason.utils;

class StringSort {

    public inline static function sort(a:String, b:String):Int {
        if (a == b) return 0;
        else if (a > b) return 1;
        else return -1;
    }

}
