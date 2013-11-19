package net.rezmason.scourge.textview;

class Colors {
    public inline static function white():Color return {r:1, g:1, b:1};

    public inline static function mult(color:Color, val:Float):Color {
        return {
            r: color.r * val,
            g: color.g * val,
            b: color.b * val,
        }
    }

    public inline static function fromHex(rgb:Int):Color {
        return {
            r: (rgb >> 16 & 0xFF) / 0xFF,
            g: (rgb >> 8  & 0xFF) / 0xFF,
            b: (rgb >> 0  & 0xFF) / 0xFF
        }
    }
}
