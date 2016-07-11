package net.rezmason.scourge;

using net.rezmason.utils.CharCode;

class ScourgeStrings {
    public inline static var BODY_GLYPHS:String = ' пгчцълкпрншьэмж';
    public inline static var HEAD_GLYPHS:String = 'ΩßŒ£&∑¶¥';
    public inline static var BOARD_CODE:Int = '+'.code(); // ¤
    public inline static var WALL_CODE:Int = '┼'.code();
    public inline static var BODY_CODE:Int = '•'.code();
    public inline static var BITE_CODE:Int = ''.code();
    public inline static var ILLEGAL_BITE_CODE:Int = '◊'.code();
    public inline static var ILLEGAL_BODY_CODE:Int = 'ø'.code();
    public inline static var LEGAL_BITE_TARGET_CODE:Int = 'Δ'.code();
    public inline static var BLANK_CODE:Int = ' '.code();
}
