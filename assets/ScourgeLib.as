package {
	
	import flash.display.Sprite;
	import flash.text.Font;
	import flash.text.TextField;
	import flash.text.TextFormat;
	
	public class ScourgeLib extends Sprite {
		[Embed(source='well_button_base.svg')]
		public static const WellButtonHitState_Old:Class;
		[Embed(source='swap_button_base.svg')]
		public static const WellButtonHitState:Class;
		[Embed(source='rotate.svg')]
		public static const RotateSymbol:Class;
		[Embed(source='bite.svg')]
		public static const BiteSymbol:Class;
		[Embed(source='swap.svg')]
		public static const SwapSymbol:Class;
		
		[Embed(source='biteicon1.svg')]
		public static const BiteIcon1:Class;
		[Embed(source='biteicon2.svg')]
		public static const BiteIcon2:Class;
		[Embed(source='biteicon3.svg')]
		public static const BiteIcon3:Class;
		
		[Embed(source='skip.svg')]
		public static const SkipSymbol:Class;
		[Embed(source='skip_button_base.svg')]
		public static const SkipButtonHitState:Class;
		
		[Embed(source='forfeit.svg')]
		public static const ForfeitSymbol:Class;
		[Embed(source='forfeit_button_base.svg')]
		public static const ForfeitButtonHitState:Class;
		
		[Embed(source='omnomnom.svg')]
		public static const BiteMask:Class;
		[Embed(source='mousepointer.svg')]
		public static const MousePointer:Class;
		
		[Embed(source='miso/miso-bold.ttf', fontName='MISO', embedAsCFF='false')]
		public static const MISO:Class;
	}
}