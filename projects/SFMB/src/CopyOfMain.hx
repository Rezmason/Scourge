package ;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.GradientType;
import flash.display.Sprite;
import flash.events.Event;
import flash.filters.BlurFilter;
import flash.geom.Matrix;
import flash.geom.Point;
import flash.geom.Rectangle;
import flash.Lib;
import flash.Memory;
import flash.utils.ByteArray;
import flash.text.TextField;
import flash.text.TextFormat;

/**
 * ...
 * @author 
 */

class Main 
{
	
	private inline static var TEX_WID:Int = 64;
	private inline static var BLUR:Float = 0.4;
	
	private inline static var BLUR_AMT:Int = Std.int(BLUR * TEX_WID);
	private inline static var GRAD_WID:Int = TEX_WID - BLUR_AMT;
	
	static var a:Array<Float> = [];
	static var r:Array<Float> = [];
	static var d:Array<Float> = [];
	
	static var xo:Array<Float> = [];
	static var yo:Array<Float> = [];
	static var xp:Array<Float> = [];
	static var yp:Array<Float> = [];
	
	static var texture_mem:BUFFER;
	static var frameBuffer:BUFFER;
	
	static var screen:Bitmap;
	
	static var textBox:TextField;
	
	static function main() 
	{
		
		var mb:Sprite = new Sprite( );
		//mb.graphics.beginFill(0x0000FF);		//BGRA
		var mat:Matrix = new Matrix();
		mat.createGradientBox(GRAD_WID, GRAD_WID, 0, BLUR_AMT / 2, BLUR_AMT / 2);
		mb.graphics.beginGradientFill(GradientType.RADIAL, [0xFF, 0x0], [1, 1], [0x0, 0xFF], mat);
		mb.graphics.drawCircle( TEX_WID / 2, TEX_WID / 2, TEX_WID / 2 );
		mb.graphics.endFill();
		
		var texture:BitmapData = new BitmapData( TEX_WID, TEX_WID, true, 0xFF000000 );
		screen = new Bitmap( new BitmapData( 600, 600, true, 0x00000000 ) );
		Lib.current.addChild( screen );
		
		texture.draw(mb);
		
		texture.applyFilter(texture, texture.rect, texture.rect.topLeft, new BlurFilter(BLUR_AMT, BLUR_AMT, 1));
		
		texture_mem = MemoryManager.allocate( TEX_WID * TEX_WID * 4 );
		frameBuffer = MemoryManager.allocate( 600 * 600 * 4 );
		
		MemoryManager.readFromBitmapData( texture, texture.rect, texture_mem );
		MemoryManager.readFromBitmapData( screen.bitmapData, screen.bitmapData.rect, frameBuffer );
		
		swapBlueToAlpha(texture_mem);
		
		textBox = new TextField();
		textBox.defaultTextFormat = new TextFormat("_sans", 10);
		Lib.current.addChild(textBox);
		textBox.y = Lib.current.stage.stageHeight - textBox.height;
		
		for ( i in 0...10000 )
		{
			r.push( (Math.random() * 10 - 5 ) * Math.PI / 180 );
			a.push( 0 );
			d.push( Math.random() * 200 );
			
			
			xo.push( Math.random() * 10 );
			yo.push( Math.random() * 10 );
			xp.push( 0 );
			yp.push( 0 );
		}
		
		Lib.current.stage.addEventListener( Event.ENTER_FRAME, update);
		//update();
		//
		
	}
	
	inline static function spit(input:Dynamic):Void
	{
		textBox.text = Std.string(input);
	}
	
	inline static function update(?event:Event):Void
	{
		
		var tm_cl:Int = Lib.getTimer( );
		clearBuffer( frameBuffer );
		tm_cl = Lib.getTimer( ) - tm_cl;
		
		var tm_bl:Int = Lib.getTimer( );
		for (i in 0...5000)
		{
			/*
			a[i] += r[i];
			
			var x:Float = 200 + d[i] * Math.cos( a[i] );
			var y:Float = 200 + d[i] * Math.sin( a[i] );
			*/
			
			xp[i] += xo[i];
			yp[i] += yo[i];
			
			if ( yp[i] > 512 ) yp[i] = 0;
			
			var x:Float = xp[i];
			var y:Float = yp[i];
			addBlendBlit( frameBuffer, 600, 600, texture_mem, TEX_WID, TEX_WID, cast x, cast y );
		}
		tm_bl = Lib.getTimer( ) - tm_bl;
		
		
		var tm_ps = Lib.getTimer( );
		postPassAlpha( frameBuffer );
		MemoryManager.writeToBitmapData(screen.bitmapData, screen.bitmapData.rect, frameBuffer);
		tm_ps = Lib.getTimer( ) - tm_ps;
		
		spit( "cl: " + tm_cl + "\tbl: " + tm_bl + "\tps: " + tm_ps );
	}
	
	inline static function clearBuffer( frameBuffer:BUFFER )
	{
		var addr:Int = frameBuffer.start;
		var eaddr:Int = frameBuffer.end;
		
		while ( addr < eaddr )
		{
			Memory.setI32( addr, 0x00FF0000 );
			
			addr += 4;
		}
	}
	
	
	inline static function swapBlueToAlpha( buffer:BUFFER )
	{
		var addr:Int = buffer.start;
		var eaddr:Int = buffer.end;
		
		while ( addr < eaddr )
		{
			Memory.setI32( addr, Memory.getI32(addr) >>> 24 );
			
			addr += 4;
		}
	}
	
	
	// BGRA
	inline static function addBlit (
							frameBuffer:BUFFER, fbrWidth:Int, fbrHeight:Int, 
							sprite:BUFFER, sprWidth:Int, sprHeight:Int, 
							x:Int, y:Int)
	{
		
		var start_addr:Int = frameBuffer.start + ((y * fbrWidth) + x) * 4;	//argb
		
		var fb_jump:Int = (fbrWidth - sprWidth) * 4;
		
		var end_addr:Int = ( (sprHeight * fbrWidth + sprWidth) * 4 ) + start_addr;
		
		var spr_addr:Int = sprite.start;
		
		while ( start_addr < end_addr )
		{
			var row_end_addr:Int = start_addr + (sprWidth * 4);
			
			while ( start_addr < row_end_addr )
			{	
				var src:Int = Memory.getI32( spr_addr );
				var dst:Int = Memory.getI32( start_addr );
				
				if (dst > 0 )
				{
					spit( "We're set" );
				}
				
				Memory.setI32( start_addr, src + dst );
			
				start_addr += 4;
				spr_addr += 4;
			}
			
			start_addr += fb_jump;
		}
		
		/*
		while ( start_addr < end_addr )
		{
			var src:Int = Memory.getI32( spr_addr );
			var dst:Int = Memory.getI32( start_addr );
				
			if (dst > 0 ) spit( "We're set" );
			
			Memory.setI32( start_addr, src + dst ); start_addr += 4; spr_addr += 4;
			start_addr += ((((spr_addr & 255) * -1) >>> 31) ^ 1) * fb_jump;
		}
		*/
	}
	
	inline static function addBlendBlit (
							frameBuffer:BUFFER, fbrWidth:Int, fbrHeight:Int, 
							sprite:BUFFER, sprWidth:Int, sprHeight:Int, 
							x:Int, y:Int)
	{
		
		var start_addr:Int = frameBuffer.start + ((y * fbrWidth) + x) * 4;	//argb
		
		var fb_jump:Int = (fbrWidth - sprWidth) * 4;
		
		var end_addr:Int = ( (sprHeight * fbrWidth + sprWidth) * 4 ) + start_addr;
		
		var spr_addr:Int = sprite.start;
		
		while ( start_addr < end_addr )
		{
			var row_end_addr:Int = start_addr + (sprWidth * 4);
			
			while ( start_addr < row_end_addr )
			{
				/* OLD
				var dst = Memory.getByte( spr_addr ) + Memory.getByte( start_addr );
				
				if (dst > 0x50) dst = 0x50;
				Memory.setI32( start_addr, dst );
				//*/
				
				//*
				Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) );  start_addr += 4;  spr_addr += 4;
				Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) );  start_addr += 4;  spr_addr += 4;
				Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) );  start_addr += 4;  spr_addr += 4;
				Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) );  start_addr += 4;  spr_addr += 4;
				Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) );  start_addr += 4;  spr_addr += 4;
				Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) );  start_addr += 4;  spr_addr += 4;
				Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) );  start_addr += 4;  spr_addr += 4;
				Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) );  start_addr += 4;  spr_addr += 4;
				//*/
				
			}
			
			start_addr += fb_jump;
		}
	}
	
	inline static function addBlendBlitPOT (
							frameBuffer:BUFFER, fbrWidth:Int, fbrHeight:Int, 
							sprite:BUFFER, sprWidth:Int, sprHeight:Int, 
							x:Int, y:Int)
	{
		
		var start_addr:Int = frameBuffer.start + ((y * fbrWidth) + x) * 4;	//argb
		
		var fb_jump:Int = (fbrWidth - sprWidth) * 4;
		
		var end_addr:Int = ( (sprHeight * fbrWidth + sprWidth) * 4 ) + start_addr;
		
		var spr_addr:Int = sprite.start;
		
		while ( start_addr < end_addr )
		{
			Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) ); start_addr += 4; spr_addr += 4;
			Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) ); start_addr += 4; spr_addr += 4;
			Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) ); start_addr += 4; spr_addr += 4;
			Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) ); start_addr += 4; spr_addr += 4;
			Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) ); start_addr += 4; spr_addr += 4;
			Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) ); start_addr += 4; spr_addr += 4;
			Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) ); start_addr += 4; spr_addr += 4;
			Memory.setI32( start_addr, Memory.getByte( spr_addr ) + Memory.getByte( start_addr ) ); start_addr += 4; spr_addr += 4;
			
			start_addr += ((((spr_addr & 255) * -1) >>> 31) ^ 1) * fb_jump;
		}
	}
	
	inline static function postPassAlpha (frameBuffer:BUFFER)
	{
		var addr:Int = frameBuffer.start;
		var eaddr:Int = frameBuffer.end;
		
		while ( addr < eaddr )
		{
			if (Memory.getI32( addr ) < 0x20 ) Memory.setI32( addr, 0 );
			addr += 4;
		}
	}
}

class MemoryManager{
	static var ba:ByteArray = function() {
		var b = new ByteArray( );
		b.length = 100000000;
		Memory.select( b );
		return b;
	}( );
	
	static var addr:Int = 0;
	
	public static function allocate( bytes:Int ) {
		if ((addr + bytes) > cast ba.length ) throw "BA is too small";
		return {start:addr, end:addr+=bytes};
	}
	
	public static function writeToBitmapData( bmd:BitmapData, rect:Rectangle, mem:BUFFER )
	{
		ba.position = mem.start;
		bmd.setPixels (bmd.rect, ba);
	}
	
	public static function readFromBitmapData( bmd:BitmapData, rect:Rectangle, ?mem:BUFFER ):BUFFER
	{
		if (mem == null )
		{
			mem = allocate( bmd.width * bmd.height * 4 );
		}
		var tba:ByteArray = bmd.getPixels (bmd.rect);
		
		ba.position = mem.start;
		ba.writeBytes (tba);
		
		return mem;
	}
}

typedef BUFFER = { start:Int, end:Int };



