package net.rezmason.scourge.textview;

class Constants {
    public static inline var STAGE_WIDTH:Int = 800;
    public static inline var STAGE_HEIGHT:Int = 600;
    public static inline var NUM_ROWS:Int = 34;
    public static inline var NUM_COLUMNS:Int = 85;
    public static inline var MARGIN:Int = 5;

    public static inline var LETTER_WIDTH:Float  = (STAGE_WIDTH  - MARGIN * 2) / NUM_COLUMNS;
    public static inline var LETTER_HEIGHT:Float = (STAGE_HEIGHT - MARGIN * 2) / NUM_ROWS;
}
