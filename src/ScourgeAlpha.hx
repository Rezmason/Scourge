//import com.eclecticdesignstudio.motion.Actuate;
import nme.Assets;
import nme.Lib;
import nme.display.Sprite;
import nme.display.StageAlign;
import nme.display.StageScaleMode;
import nme.text.AntiAliasType;
import nme.text.TextField;
import nme.text.TextFormat;

//	0xFF0090, 0xFFC800, 0x30FF00, 0x00C0FF, 0xFF6000, 0xC000FF, 0x0030FF, 0x606060

class ScourgeAlpha {

	var canvas:Sprite;

	public function new(scene:Sprite) {

		canvas = new Sprite();
		scene.addChild(canvas);

		thing1();

	}

	private function thing1():Void {
		var font = Assets.getFont("assets/ProFontX.ttf");
		var format = new TextFormat(font.fontName, 14, 0xFFFFFF);

		var textField = new TextField();
		textField.antiAliasType = AntiAliasType.ADVANCED;
		textField.thickness = 30;
		textField.sharpness = -100;
		textField.defaultTextFormat = format;
		textField.selectable = false;
		textField.embedFonts = true;
		textField.width = 800;
		textField.height = 600;
		textField.x = 0;
		textField.y = 0;


		//for (ike in 0...20) textField.appendText("\n\nX X X X X X X X X X X X X X X X X X X X X X X X");

		var lines:Array<String> = [];
		lines.push(colorize("Scourge Alpha ", 0x30FF00) + "-" + colorize(" Flash build", 0x00C0FF));
		lines.push(colorize("¬  > Ω Î @ Δ ◊ ¤ _ { } [ ] • ø", 0xFFC800));
		lines.push(colorize("' ' ' ' ' ' ' ' ' ' ' ' ' ' ' '", 0xFF0090));
		lines.push("> _");
		textField.htmlText = lines.join("\n");

		canvas.addChild(textField);
	}

	private function colorize(str:String, color:Int):String {
		return "<FONT COLOR='#" + StringTools.hex(color) + "'>" + str + "</FONT>";
	}

	public static function main() {
		Lib.current.stage.align = StageAlign.TOP_LEFT;
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;
		new ScourgeAlpha(Lib.current);
	}


}
