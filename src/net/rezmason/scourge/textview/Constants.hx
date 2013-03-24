package net.rezmason.scourge.textview;

class Constants {
    public static inline var STAGE_WIDTH:Int = 800;
    public static inline var STAGE_HEIGHT:Int = 600;
    public static inline var SCALE:Int = 1;
    public static inline var ROWS:Int = 35 * SCALE; // 35
    public static inline var COLUMNS:Int = 85 * SCALE; // 85
    public static inline var TOTAL_CHARS:Int = ROWS * COLUMNS;
    public static inline var MARGIN:Int = 5;

    public inline static var MAX_DEPTH:Float = 100;
    public inline static var VANISHING_POINT_X:Float = STAGE_WIDTH  / 2;
    public inline static var VANISHING_POINT_Y:Float = STAGE_HEIGHT / 2;
    public inline static var FOCAL_LENGTH:Float = 400;

    public static inline var LETTER_WIDTH:Float  = (STAGE_WIDTH  - MARGIN * 2) / COLUMNS;
    public static inline var LETTER_HEIGHT:Float = (STAGE_HEIGHT - MARGIN * 2) / ROWS;
}
