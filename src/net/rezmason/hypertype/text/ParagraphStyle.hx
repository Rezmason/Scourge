package net.rezmason.hypertype.text;

class ParagraphStyle {

    static var paragraphAlignByName:Map<String, ParagraphAlign> = makeParagraphAlignByName();

    public var align(default, null):ParagraphAlign;

    public var name(default, null):String;
    public var basis(default, null):String;

    public function new(dec:Dynamic):Void {
        align = paragraphAlignByName[dec.align];
        this.name = dec.name;
        this.basis = dec.basis;
    }

    public function toString():String {
        return '¶ name:$name align:$align';
    }

    public function inherit(parent:ParagraphStyle):Void {
        if (parent != null) {
            if (align == null) align = parent.align;
            if (basis == parent.name) basis = parent.basis;
        }
    }

    public function connectBases(bases:Map<String, ParagraphStyle>):Void {
        inherit(bases['']);
    }

    static function makeParagraphAlignByName():Map<String, ParagraphAlign> {
        return [
            'left' => ALIGN_LEFT,
            'center' => ALIGN_CENTER,
            'right' => ALIGN_RIGHT,
            'justify' => ALIGN_JUSTIFY(ALIGN_LEFT),
            'justify-left' => ALIGN_JUSTIFY(ALIGN_LEFT),
            'justify-center' => ALIGN_JUSTIFY(ALIGN_CENTER),
            'justify-right' => ALIGN_JUSTIFY(ALIGN_RIGHT),
        ];
    }
}
