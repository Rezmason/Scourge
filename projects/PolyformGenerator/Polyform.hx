package;

import Step.*;

abstract Polyform(String) {
    
    inline function new(str) this = str;
    @:to public inline function toString() return this;
    public inline static function monoform(winding) return new Polyform([for (ike in 0...winding) R].join(''));
    public inline static function nihiloform() return new Polyform('');
    public inline function length() return this.length;
    public inline function perimeter() return this.length;

    public inline static function sortFunction(p1:Polyform, p2:Polyform) {
        return (p1.toString() < p2.toString()) ? -1 : (p1.toString() == p2.toString()) ? 0 : 1;
    }

    public inline function eachStep() {
        var itr = 0;
        return { hasNext:function() return itr < length(), next:function() return this.charAt(itr++) };
    }

    public inline function reflect(neat = true) {
        var str = '';
        for (step in eachStep()) str = step + str;
        return new Polyform(neat ? minRot(str) : str);
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

    public inline function numReflections() return reflect() == this ? 1 : 2;

    public inline function numRotations() {
        return
            if (this.substr(this.length >> 2) + this.substr(0, this.length >> 2) == this) 1
            else if (this.substr(this.length >> 1) + this.substr(0, this.length >> 1) == this) 2
            else 4;
    }

    public inline function numTransforms() return numReflections() * numRotations();

    public inline function expand(rules:Map<String, String>) {
        var expansions = new Map();
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
                        var string = minRot(this.substr(overrun, ike - overrun) + rep + this.substr(ike + pLen - overrun));
                        expansions[string] = new Polyform(string);
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

    inline function minRot(str:String) {
        var lowestString = str;
        for (ike in 1...str.length) {
            var candidate = str.substr(str.length - ike) + str;
            if (candidate < lowestString) lowestString = candidate;
        }
        return lowestString.substr(0, str.length);
    }
}
