package;

import haxe.io.Bytes;
import lime.app.Application;
import lime.graphics.Image;
import net.rezmason.hypertype.Strings;
import net.rezmason.utils.display.FlatFontGenerator;
import sys.io.File;

class ScourgeAssetGen extends Application {

    override public function onPreloadComplete():Void {
        
        var profontChars:String = [
            ' ',
            Strings.ALPHANUMERICS,
            Strings.PUNCTUATION,
            Strings.SYMBOLS,
            Strings.WEIRD_SYMBOLS,
        ].join('');

        var matrixChars:String = Strings.MATRIX_CHARS + Strings.MATRIX_UNUSED_CHARS;

        var characterSets:Array<CharacterSet> = [
            {chars:profontChars, size:300, size2:300, fontID:'ProFont'},
            {chars:Strings.SMALL_CYRILLICS, size:400, size2:300, fontID:'ProFont_Cy'},
            {chars:Strings.BOX_SYMBOLS, size:300, size2:300, fontID:'SourceProFont'},
        ];
        FlatFontGenerator.flatten(characterSets, 72, 72, 1, 50, deployFont.bind('full'));

        characterSets = [{chars:matrixChars, size:218, size2:218, fontID:'MatrixCode'}];
        FlatFontGenerator.flatten(characterSets, 72, 72, 1, 50, deployFont.bind('matrix'));

        /*
        var current:Sprite = Lib.current;
        current.stage.addEventListener(flash.events.MouseEvent.MOUSE_MOVE, function(e) {
            if (current.width <= current.stage.stageWidth) current.x = 0;
            else current.x = (current.stage.mouseX / current.stage.stageWidth ) * (current.stage.stageWidth  - current.width );

            if (current.height <= current.stage.stageHeight) current.y = 0;
            else current.y = (current.stage.mouseY / current.stage.stageHeight) * (current.stage.stageHeight - current.height);
        });
        
        FlatFontGenerator.flatten(sets, 72, 72, 1, 20, deployFont.bind(_, "full"));
        MetaballTextureGenerator.makeTexture(30, 0.62, 20, deployImage.bind(_, "metaball"));
        GlobTextureGenerator.makeTexture(512, deployImage.bind(_, "glob"));
        */


        Sys.exit(0);
    }

    static function deployFont(id:String, htf:Bytes, image:Image):Void {
        var path = '../../../../../../../../assets/flatfonts/';
        File.saveBytes('$path${id}.htf', htf);
        File.saveContent('${path}${id}.png', image.encode().toString());
    }

    static function deployImage(image:Image, id:String):Void {
        var path = '../../../../../../../../assets/';
        File.saveContent('${path}${id}.png', image.encode().toString());
        /*
        var sprite:Sprite = new Sprite();
        sprite.addChild(new Bitmap(image));
        var fileRef = null;
        sprite.addEventListener("click", function(_) {
            var bytesOutput:BytesOutput = new BytesOutput();
            var writer:Writer = new Writer(bytesOutput);
            var data = Tools.build32ARGB(image.width, image.height, Bytes.ofData(image.getPixels(image.rect)));
            writer.write(data);
            fileRef = new FileReference();
            fileRef.save(bytesOutput.getBytes().getData(), id + ".png");
            Lib.current.removeChild(sprite);
        });

        Lib.current.addChild(sprite);
        */
    }
}
