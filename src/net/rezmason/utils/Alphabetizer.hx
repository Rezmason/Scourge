package net.rezmason.utils;

import haxe.ds.ArraySort;

class Alphabetizer {

    public inline static function a2z<T>(keyIterator:Iterator<String>):Iterator<String> {
        var keys:Array<String> = [];
        for (key in keyIterator) keys.push(key);
        ArraySort.sort(keys, StringSort.sort);
        return keys.iterator();
    }

}
