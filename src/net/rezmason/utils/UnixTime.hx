package net.rezmason.utils;

class UnixTime {

    public inline static function now():Int {
        return Std.int(Date.now().getTime() / 1000);
    }

}
