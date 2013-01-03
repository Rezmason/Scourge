package net.rezmason.utils;

class Alphabetizer {

    public inline static function a2z<T>(keyIterator:Iterator<String>):Iterator<String> {
        var keys:Array<String> = [];
        for (key in keyIterator) keys.push(key);
        keys.sort(StringSort.sort);
        return keys.iterator();
    }

}
