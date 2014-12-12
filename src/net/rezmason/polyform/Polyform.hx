package net.rezmason.polyform;

import net.rezmason.polyform.Step.*;

abstract Polyform(String) {
    
    inline function new(str) this = str;
    @:to public inline function toString() return this;
    public inline static function monoform(winding) return new Polyform([for (ike in 0...winding) R].join(''));
    public inline static function nihiloform() return new Polyform('');
    public inline function length() return this.length;
    public inline function perimeter() return this.length;
    public inline static function sortFunction(p1:Polyform, p2:Polyform) return (p1 < p2) ? -1 : (p1 == p2) ? 0 : 1;
    @:op(A < B) public function isLowerThan(rhs):Bool return toString() < rhs.toString();
    @:op(A == B) public function isEqualTo(rhs):Bool return toString() == rhs.toString();
    @:op(A > B) public function isGreaterThan(rhs):Bool return toString() > rhs.toString();

    public inline function eachStep() {
        var itr = 0;
        return { hasNext:function() return itr < length(), next:function() return this.charAt(itr++) };
    }

    inline function min() {
        var mirror = reflect().minRot();
        var self = minRot();
        return mirror < self ? mirror : self;
    }

    inline function minRot() {
        var lowestString = this;
        for (ike in 1...length()) {
            var candidate = this.substr(length() - ike) + this;
            if (candidate < lowestString) lowestString = candidate;
        }
        return new Polyform(lowestString.substr(0, length()));
    }

    public inline function reflect() {
        var str = '';
        for (step in eachStep()) str = step + str;
        return new Polyform(str);
    }

    public inline function rotate(amount) {
        var val = 0;
        var cut = 0;
        for (step in eachStep()) {
            cut++;
            val += (step == R) ? 1 : (step == L) ? -1 : 0;
            if (val == amount) break;
        }
        return new Polyform(this.substr(cut) + this.substr(0, cut));
    }

    public inline function numReflections() return reflect().minRot() == this ? 1 : 2;

    public inline function numRotations() {
        return
            if      (this.substr(Std.int(this.length / 4)) + this.substr(0, Std.int(this.length / 4)) == this) 1
            else if (this.substr(Std.int(this.length / 2)) + this.substr(0, Std.int(this.length / 2)) == this) 2
            else    4;
    }

    public inline function expand(rules:Map<String, String>) {
        var expansions:Map<String, Polyform> = new Map();
        var len = this.length;
        for (pattern in rules.keys()) {
            var rep = rules[pattern];
            if (pattern.length <= this.length) {
                var pLen = pattern.length;
                var str = this + this;
                for (ike in 0...len) {
                    var matched = true;
                    for (jen in 0...pLen) {
                        if (this.charAt((ike + jen) % len) != pattern.charAt(jen)) {
                            matched = false;
                            break;
                        }
                    }
                    if (matched) {
                        var overrun = ike + pLen - len;
                        if (overrun < 0) overrun = 0;
                        var start = this.substr(overrun, ike - overrun);
                        var end = this.substr(pLen + ike - overrun);
                        var expansion = new Polyform('$start$rep$end').min();
                        expansions[expansion] = expansion;
                    }
                }
            }
        }
        return expansions;
    }

    public inline function march(points:Array<{x:Int, y:Int}>, headings:Array<Int>) {
        var x = 0;
        var y = 0;
        var heading = 0;
        for (step in eachStep()) {
            heading = (heading + ((step == R) ? 1 : (step == L) ? 3 : 0)) % 4;
            headings.push(heading);
            switch (heading) {
                case 0: x++;
                case 1: y++;
                case 2: x--;
                case 3: y--;
            }
            points.push({x:x, y:y});
        }
    }

    public inline function winding() {
        var val = 0;
        for (step in eachStep()) val += (step == R) ? 1 : (step == L) ? -1 : 0;
        return val;
    }
}
