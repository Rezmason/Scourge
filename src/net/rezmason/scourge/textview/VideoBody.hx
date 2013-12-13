package net.rezmason.scourge.textview;

import haxe.Utf8;

import flash.geom.Matrix3D;
import flash.geom.Rectangle;
import flash.geom.Vector3D;

import flash.events.Event;
import flash.media.Camera;
import flash.media.Video;
import flash.Vector;

import net.rezmason.gl.utils.BufferUtil;

import net.rezmason.scourge.textview.core.Glyph;
import net.rezmason.scourge.textview.core.Body;
import net.rezmason.scourge.textview.core.BodyScaleMode;
import net.rezmason.scourge.textview.core.GlyphTexture;
import net.rezmason.scourge.textview.core.Interaction;

using net.rezmason.scourge.textview.core.GlyphUtils;

class VideoBody extends Body {

    inline static var GLYPH_TOWER_HEIGHT:Int = 1;

    var glyphTowers:Array<Array<Array<Glyph>>>;
    var videoCamera:Camera;
    var videoVec:Vector<UInt>;
    var videoRect:Rectangle;

    var numRows:Int;
    var numCols:Int;

    var time:Float;

    public function new(bufferUtil:BufferUtil, glyphTexture:GlyphTexture):Void {

        super(bufferUtil, glyphTexture);

        scaleMode = WIDTH_FIT;

        time = 0;

        videoCamera = Camera.getCamera();
        if (videoCamera == null) return;

        videoCamera.setMode(320 >> 2, 240 >> 2, 30, true);
        numRows = videoCamera.height;
        numCols = videoCamera.width;
        videoVec = new Vector();
        videoVec.length = numRows * numCols;
        videoRect = new Rectangle(0, 0, numCols, numRows);
        var vid:Video = new Video(videoCamera.width, videoCamera.height);
        vid.attachCamera(videoCamera);
        // flash.Lib.current.stage.addChild(vid);
        videoCamera.addEventListener(Event.VIDEO_FRAME, receiveFrame);


        growTo(GLYPH_TOWER_HEIGHT * numRows * numCols);

        glyphTowers = [];

        var glyphID:Int = 0;
        for (row in 0...numRows) {

            var glyphRow:Array<Array<Glyph>> = [];
            glyphTowers.push(glyphRow);

            for (col in 0...numCols) {

                var x:Float = ((col + 0.5) / numCols - 0.5) * 0.5 * numCols / numRows;
                var y:Float = ((row + 0.5) / numRows - 0.5) * 0.5;
                var z:Float = 0.;

                var charCode:Int = 65 + Std.random(26);
                var color:Color = Colors.white();

                var glyphTower:Array<Glyph> = [];

                for (ike in 0...GLYPH_TOWER_HEIGHT) {
                    var glyph:Glyph = glyphs[glyphID];

                    glyphTower.push(glyph);

                    glyph.set_shape(x, y, z, 1, 0);
                    glyph.set_color(color);
                    glyph.set_i(0);
                    glyph.set_char(charCode, glyphTexture.font);
                    glyph.set_paint(glyph.id | id << 16);

                    z += 0.01;
                    color = Colors.mult(color, 0.2);

                    glyphID++;
                }

                glyphRow.push(glyphTower);
            }
        }

        transform.appendScale(1, -1, 1);
    }

    override public function adjustLayout(stageWidth:Int, stageHeight:Int):Void {
        super.adjustLayout(stageWidth, stageHeight);

        var rect:Rectangle = sanitizeLayoutRect(stageWidth, stageHeight, viewRect);
        var glyphWidth:Float = rect.width * 0.015;

        setGlyphScale(glyphWidth, glyphWidth * glyphTexture.font.glyphRatio * stageWidth / stageHeight);
    }

    override public function update(delta:Float):Void {
        time += delta;

        for (row in 0...numRows) {
            for (col in 0...numCols) {

                var hex:Int = videoVec[row * numCols + col];
                var r:Float = (hex >> 16 & 0xFF) / 0xFF;
                var g:Float = (hex >> 8  & 0xFF) / 0xFF;
                var b:Float = (hex >> 0  & 0xFF) / 0xFF;

                var max:Float = (r > g && r > b) ? r : (g > b) ? g : b;
                r *= 1 / max;
                g *= 1 / max;
                b *= 1 / max;

                var glyphTower:Array<Glyph> = glyphTowers[row][col];

                /*
                var d:Float = (row * numCols + col) / (numRows * numCols);
                var p:Float = (Math.cos(time * 3 + d * 200) * 0.5 + 1) * 0.001;
                var f:Float = (Math.cos(time * 3 + d * 200) * 0.5 + 1) * 0.4 + 0.1;
                var s:Float = (Math.cos(time * 3 + d * 300) * 0.5 + 1) * 0.1 + 0.9;
                */

                var s:Float = 1;
                var f:Float = 0.5 * max + 0.05;
                var p:Float = max * 0.1;

                for (glyph in glyphTower) {
                    /*
                    glyph.set_p(p);
                    glyph.set_f(f);
                    glyph.set_s(s * (glyph.get_z() + 1));
                    */

                    glyph.set_s(s);
                    glyph.set_f(f);
                    glyph.set_p(p);

                    glyph.set_rgb(r, g, b);

                    r *= 0.2;
                    g *= 0.2;
                    b *= 0.2;

                    s *= 2;
                }
            }
        }

        super.update(delta);
    }

    function receiveFrame(event:Event):Void {
        videoCamera.copyToVector(videoRect, videoVec);
    }
}
