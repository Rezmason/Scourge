package net.rezmason.utils;

class SkipIterator {
    var min:Int;
    var max:Int;
    var step:Int;
    public function new(min, max, step = 1) {
        this.min = min;
        this.max = max;
        this.step = step;
    }

    public function hasNext() return min < max;
    public function next() {
        min += step;
        return min - step;
    }
}
