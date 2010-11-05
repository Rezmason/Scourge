package net.rezmason.scourge;

class Layout {
	
	public static var UNIT_SIZE:Int = 20;
	public static var WELL_WIDTH:Float = 210;
	public static var WELL_BORDER:Float = 10;
	public static var BAR_WIDTH:Float = 230;
	public static var BAR_MARGIN:Float = (BAR_WIDTH - WELL_WIDTH) / 2;
	public static var BAR_HEIGHT:Float = 600;
	public static var BOARD_BORDER:Int = 10;
	public static var TIMER_HEIGHT:Float = 40;
	public static var STAT_PANEL_HEIGHT:Float = Layout.BAR_HEIGHT - 4 * Layout.BAR_MARGIN - Layout.WELL_WIDTH - Layout.TIMER_HEIGHT;
	
}