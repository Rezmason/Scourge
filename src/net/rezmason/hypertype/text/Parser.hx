package net.rezmason.hypertype.text;

import haxe.Utf8;
import net.rezmason.hypertype.text.Sigil.*;

using Lambda;

class Parser {

    static var defaultStyle(default, null):Style = makeDefaultStyle();
    static var defaultParagraphStyle(default, null):ParagraphStyle = makeDefaultParagraphStyle();

    static var styleTypes:Map<String, Class<Style>> = [
        STYLE => Style,
        ANIMATED_STYLE => AnimatedStyle,
        BUTTON_STYLE => ButtonStyle,
    ];

    public inline static function makeEmptyOutput():ParsedOutput {
        var span:Span = getSpan();
        var paragraph:Paragraph = getParagraph();
        return {
            input:'',
            output:'§',
            spans:[span],
            interactiveSpans:[],
            paragraphs:[paragraph],
            styles:[''=>defaultStyle],
            paragraphStyles:[''=>defaultParagraphStyle],
            recycledSpans:[],
            recycledParagraphs:[],
            spansByStyleName:[''=>[span]],
        };
    }

    public static inline function parse(
        input:String, 
        styles:Map<String, Style> = null, 
        paragraphStyles:Map<String, ParagraphStyle> = null, 
        startMouseID:Int = 0, 
        recycledSpans:Array<Span> = null,
        recycledParagraphs:Array<Paragraph> = null
    ):ParsedOutput {

        var newStyles:Array<Style> = [];
        var newParagraphStyles:Array<ParagraphStyle> = [];
        var spans:Array<Span> = [];
        var interactiveSpans:Array<Span> = [null];
        var paragraphs:Array<Paragraph> = [];
        var currentMouseID:Int = startMouseID + 1;
        var spansByStyleName:Map<String, Array<Span>> = new Map();
        var paragraphsByParagraphStyleName:Map<String, Array<Paragraph>> = new Map();

        if (styles == null) styles = [''=>defaultStyle];
        for (style in styles) spansByStyleName[style.name] = [];
        if (recycledSpans == null) recycledSpans = [];

        if (paragraphStyles == null) paragraphStyles = [''=>defaultParagraphStyle];
        for (paragraphStyle in paragraphStyles) paragraphsByParagraphStyleName[paragraphStyle.name] = [];
        if (recycledParagraphs == null) recycledParagraphs = [];

        var initSpan:Span = getSpan(recycledSpans, defaultStyle, startMouseID);
        spans.push(initSpan);
        spansByStyleName[''].push(initSpan);

        var initParagraph:Paragraph = getParagraph(recycledParagraphs, defaultParagraphStyle);
        paragraphs.push(initParagraph);
        paragraphsByParagraphStyleName[''].push(initParagraph);

        var left:String = '';
        var right:String = input;
        while (right.length > 0) {
            var startIndex:Int = -1;
            var styleType:Class<Style> = null;
            var isParagraphStyle:Bool = false;

            // Find the next sigil

            for (sigil in [STYLE, ANIMATED_STYLE, BUTTON_STYLE, PARAGRAPH_STYLE]) {
                var index:Int = right.indexOf(sigil);
                if (index != -1 && (startIndex == -1 || startIndex > index)) {
                    startIndex = index;
                    styleType = styleTypes[sigil];
                    isParagraphStyle = sigil == PARAGRAPH_STYLE;
                }
            }

            // Find the close brace

            if (startIndex != -1) {
                if (startIndex > 0) left = left + right.substr(0, startIndex);

                right = right.substr(startIndex, right.length);
                right = Utf8.sub(right, 1, Utf8.length(right));

                var endIndex:Int = right.indexOf('}');
                if (endIndex != -1) {

                    var guts:String = right.substr(0, endIndex + 1);
                    guts = Utf8.sub(guts, 1, Utf8.length(guts)    ); // Remove leading  '{'
                    guts = Utf8.sub(guts, 0, Utf8.length(guts) - 1); // Remove trailing '}'

                    var tag:Dynamic = guts.indexOf(':') == -1 ? {name:guts} : parseTag(guts);

                    if (isParagraphStyle) {
                        var paragraphStyle:ParagraphStyle = getParagraphStyle(tag, paragraphStyles);
                        if (paragraphStyle != defaultParagraphStyle && paragraphStyles[paragraphStyle.name] == null) {
                            paragraphStyles[paragraphStyle.name] = paragraphStyle;
                            paragraphsByParagraphStyleName[paragraphStyle.name] = [];
                            newParagraphStyles.push(paragraphStyle);
                        }

                        right = right.substr(endIndex, right.length);
                        right = Utf8.sub(right, 1, Utf8.length(right));

                        if (right.indexOf(PARAGRAPH_STYLE) != 0) {
                            var paragraph:Paragraph = getParagraph(recycledParagraphs, paragraphStyle, tag.id);
                            paragraphs.push(paragraph);
                            paragraphsByParagraphStyleName[paragraphStyle.name].push(paragraph);

                            left = left + PARAGRAPH_STYLE;
                        }

                    } else {
                        var style:Style = getStyle(styleType, tag, styles);
                        if (style != defaultStyle && styles[style.name] == null) {
                            styles[style.name] = style;
                            spansByStyleName[style.name] = [];
                            newStyles.push(style);
                        }

                        right = right.substr(endIndex, right.length);
                        right = Utf8.sub(right, 1, Utf8.length(right));

                        var skipSpan:Bool = false;
                        for (sigil in [STYLE, ANIMATED_STYLE, BUTTON_STYLE]) {
                            if (right.indexOf(sigil) == 0) {
                                skipSpan = true;
                                break;
                            }
                        }

                        if (!skipSpan) {
                            var span:Span = getSpan(recycledSpans, style, style.isInteractive ? currentMouseID : startMouseID, tag.id);
                            spans.push(span);
                            spansByStyleName[style.name].push(span);

                            if (style.isInteractive) {
                                interactiveSpans.push(span);
                                currentMouseID++;
                            }

                            left = left + STYLE;
                        }
                    }
                }
            } else {
                break;
            }
        }

        // Resolve bases

        for (topStyle in newStyles) {
            var style:Style = topStyle;
            var dependencyStack:Array<String> = [];
            while (true) {
                dependencyStack.push(style.name);

                if (style.basis == null) break;
                if (dependencyStack.has(style.basis)) {
                    throw 'Cyclical style dependency, pal: ( $dependencyStack )';
                }

                style = styles[style.basis];
                if (style == null) break;
            }

            while (dependencyStack.length > 0) {
                style = styles[dependencyStack.pop()];
                if (style.basis != null) style.inherit(styles[style.basis]);
            }
        }

        for (style in newStyles) {
            style.connectBases(styles);
            style.flatten();
        }

        for (span in spans) span.connect();

        // trace('${newStyles.length} styles created.');

        return {
            input:input,
            output:left + right,
            styles:styles,
            paragraphStyles:paragraphStyles,
            spans:spans,
            interactiveSpans:interactiveSpans,
            paragraphs:paragraphs,
            recycledSpans:recycledSpans,
            recycledParagraphs:recycledParagraphs,
            spansByStyleName:spansByStyleName
        };
    }

    inline static function getStyle(styleType:Class<Style>, tag:Dynamic, styles:Map<String, Style>):Style {
        if (tag.name == null) throw 'Style declaration must include name, chief: ( $tag )';
        var style:Style = styles[cast tag.name];
        if (style == null) style = Type.createInstance(styleType, [tag]);
        return style;
    }

    inline static function getParagraphStyle(tag:Dynamic, paragraphStyles:Map<String, ParagraphStyle>):ParagraphStyle {
        if (tag.name == null) throw 'Paragraph style declaration must include name, hombre: ( $tag )';
        var paragraphStyle:ParagraphStyle = paragraphStyles[cast tag.name];
        if (paragraphStyle == null) paragraphStyle = new ParagraphStyle(tag);
        return paragraphStyle;
    }

    inline static function getSpan(recycledSpans:Array<Span> = null, style:Style = null, mouseID:Int = 0, id:String = null):Span {
        var span:Span = (recycledSpans == null ? null : recycledSpans.pop());
        if (span == null) span = new Span();
        if (style == null) style = defaultStyle;
        else span.reset();
        span.init(style, mouseID, id);
        return span;
    }

    inline static function getParagraph(recycledParagraphs:Array<Paragraph> = null, paragraphStyle:ParagraphStyle = null, id:String = null):Paragraph {
        var paragraph:Paragraph = (recycledParagraphs == null ? null : recycledParagraphs.pop());
        if (paragraph == null) paragraph = new Paragraph();
        if (paragraphStyle == null) paragraphStyle = defaultParagraphStyle;
        else paragraph.reset();
        paragraph.init(paragraphStyle, id);
        return paragraph;
    }

    inline static function makeDefaultStyle():Style {
        var style:Style = new Style(defaultStyleTag());
        style.flatten();
        return style;
    }

    inline static function makeDefaultParagraphStyle():ParagraphStyle {
        return new ParagraphStyle(defaultParagraphStyleTag());
    }

    inline static function parseTag(input:String):Dynamic {

        var tag:Dynamic = {};
        var left:String = '';
        var right:String = input;

        // Remove spaces

        while (right.length > 0) {
            var startIndex:Int = right.indexOf(' ');
            if (startIndex == -1) break;
            left = left + right.substr(0, startIndex);
            right = right.substr(startIndex + 1, right.length);
        }

        right = left + right;

        while (right.length > 0) {

            // Search for colon
            var firstColonIndex:Int = right.indexOf(':');
            if (firstColonIndex == -1) break;

            var field:String = right.substr(0, firstColonIndex);
            var value:Dynamic = null;

            right = right.substr(firstColonIndex + 1, right.length);

            // Search for second colon
            var valueString:String = '';
            var secondColonIndex:Int = right.indexOf(':');
            if (secondColonIndex == -1) {
                valueString = right;
                right = '';
            } else {
                // Search for last comma before second colon
                var lastCommaIndex:Int = right.substr(0, secondColonIndex).lastIndexOf(',');
                valueString = right.substr(0, lastCommaIndex);
                right = right.substr(lastCommaIndex + 1, right.length);
            }

            if (valueString.indexOf('[') == 0) {
                var valueArray:Array<String> = [];
                valueString = valueString.substr(1, valueString.length);
                valueString = valueString.substr(0, valueString.length - 1);
                while (valueString.length > 0) {
                    var commaIndex:Int = valueString.indexOf(',');
                    if (commaIndex == -1) {
                        valueArray.push(valueString);
                        valueString = '';
                    } else {
                        valueArray.push(valueString.substr(0, commaIndex));
                        valueString = valueString.substr(commaIndex + 1, valueString.length);
                    }
                }
                value = valueArray;
            } else {
                value = valueString;
            }

            Reflect.setField(tag, field, value);
        }

        return tag;
    }

    inline static function defaultStyleTag():Dynamic return {name:'', r:1, g:1, b:1, i:0, f:0.5, a:0, h:1, s:1, p:0};
    inline static function defaultParagraphStyleTag():Dynamic return {name:'', align:'left'};
}
