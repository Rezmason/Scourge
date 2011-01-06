/**
* Graphics by Grant Skinner. Dec 5, 2010
* Visit www.gskinner.com/blog for documentation, updates and more free code.
*
*
* Copyright (c) 2010 Grant Skinner
* 
* Permission is hereby granted, free of charge, to any person
* obtaining a copy of this software and associated documentation
* files (the "Software"), to deal in the Software without
* restriction, including without limitation the rights to use,
* copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the
* Software is furnished to do so, subject to the following
* conditions:
* 
* The above copyright notice and this permission notice shall be
* included in all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
* OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
* HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
* OTHER DEALINGS IN THE SOFTWARE.
**/

(function(window) {

/**
* Constructs a new Graphics instance.
* @param instructions Optional. The vector drawing instruction that this Graphics will use. See the instructions property for information.
* @class A Graphics instance encapsulates a set of drawing instructions so they can be rendered to the stage within the current context. Generally, you would use the drawing API
* exposed by Graphics to generate instructions rather than setting them directly. Note that you can use Graphics without any dependency on the Easel framework by calling draw() directly,
* or it can be used with the Shape object to draw vector graphics within the context of an Easel display list.<br/><br/>
* Note that all drawing methods in Graphics return the Graphics instance, so they can be chained together. For example, the following line of code would draw a rectangle with a red stroke and blue fill:<br/>
* myGraphics.beginStroke("#F00").beginFill("#00F").drawRect(20, 20, 100, 50);
* @augments DisplayObject
**/
function Graphics(instructions) {
	this.init(instructions);
}
var p = Graphics.prototype;

// static public methods:
	
	/**
	* Returns a CSS compatible color string based on the specified RGB numeric color values in the format "rgba(255,255,255,1.0)", or if alpha is null then in the format "rgb(255,255,255)". For example,
	* Graphics.getRGB(50,100,150,0.5) will return "rgba(50,100,150,0.5)".
	* @param r The red component for the color, between 0 and 0xFF (255).
	* @param g The green component for the color, between 0 and 0xFF (255).
	* @param b The blue component for the color, between 0 and 0xFF (255).
	* @param alpha Optional. The alpha component for the color where 0 is fully transparent and 1 is fully opaque.
	* @static
	**/
	Graphics.getRGB = function(r, g, b, alpha) {
		if (alpha == null) {
			return "rgb("+r+","+g+","+b+")";
		} else {
			return "rgba("+r+","+g+","+b+","+alpha+")";
		}
	}
	
	/**
	* Returns a CSS compatible color string based on the specified HSL numeric color values in the format "hsla(360,100,100,1.0)", or if alpha is null then in the format "hsl(360,100,100)". For example,
	* Graphics.getHSL(150,100,70) will return "hsl(150,100,70)".
	* @param hue The hue component for the color, between 0 and 360.
	* @param saturation The saturation component for the color, between 0 and 100.
	* @param lightness The lightness component for the color, between 0 and 100.
	* @param alpha Optional. The alpha component for the color where 0 is fully transparent and 1 is fully opaque.
	* @static
	**/
	Graphics.getHSL = function(hue, saturation, lightness, alpha) {
		if (alpha == null) {
			return "hsl("+(hue%360)+","+saturation+"%,"+lightness+"%)";
		} else {
			return "hsla("+(hue%360)+","+saturation+"%,"+lightness+"%,"+alpha+")";
		}
	}

// public properties:
	/** @private **/
	p._strokeInstructions = null;
	/** @private **/
	p._strokeStyleInstructions = "";
	/** @private **/
	p._fillInstructions = null;
	/** @private **/
	p._instructions = null;
	/** @private **/
	p._oldInstructions = "";
	/** @private **/
	p._activeInstructions = "";
	/** @private **/
	p._active = false;
	/** @private **/
	p._dirty = false;
	/** @private **/
	p._assets = null;
	
// constructor:
	/** @private **/
	p.init = function(instructions) {
		this._instructions = this._oldInstructions = (instructions ? instructions : "");
		this._assets = [];
	}
	
// public methods:
	p.draw = function(ctx) {
		if (this._dirty) {
			this._updateInstructions();
		}
		var c = ctx;
		var a = this._assets;
		var o = null;
		eval(this._instructions);
	}
	
// public methods that map directly to context 2D calls:
	/**
	* Moves the drawing point to the specified position.
	* @param x
	* @param y
	**/
	p.moveTo = function(x,y) {
		this._activeInstructions += "c.moveTo("+x+","+y+");";
		return this;
	}
	
	/**
	* Draws a line from the current drawing point to the specified position, which become the new current drawing point. For detailed information, read the <a href="http://www.whatwg.org/specs/web-apps/current-work/multipage/the-canvas-element.html#complex-shapes-(paths)">whatwg spec</a>.
	* @param x
	* @param y
	**/
	p.lineTo = function(x,y) {
		this._dirty = this._active = true;
		this._activeInstructions += "c.lineTo("+x+","+y+");";
		return this;
	}
	
	/**
	* Draws an arc with the specified control points and radius.  For detailed information, read the <a href="http://www.whatwg.org/specs/web-apps/current-work/multipage/the-canvas-element.html#complex-shapes-(paths)">whatwg spec</a>.
	* @param x1
	* @param y1
	* @param x2
	* @param y2
	* @param radius
	**/
	p.arcTo = function(x1, y1, x2, y2, radius) {
		this._dirty = this._active = true;
		this._activeInstructions += "c.arcTo("+x1+","+y1+","+x2+","+y2+");";
		return this;
	}
	
	/**
	* Draws an arc defined by the radius, startAngle and endAngle arguments, centered at the position (x,y). For example arc(100,100,20,0,Math.PI*2) would draw a full circle with a radius of 20 centered at 100,100. For detailed information, read the <a href="http://www.whatwg.org/specs/web-apps/current-work/multipage/the-canvas-element.html#complex-shapes-(paths)">whatwg spec</a>.
	* @param x
	* @param y
	* @param radius
	* @param startAngle
	* @param endAngle
	* @param anticlockwise
	**/
	p.arc = function(x, y, radius, startAngle, endAngle, anticlockwise) {
		this._dirty = this._active = true;
		if (anticlockwise == null) { anticlockwise = false; }
		this._activeInstructions += "c.arc("+x+","+y+","+radius+","+startAngle+","+endAngle+","+anticlockwise+");";
		return this;
	}
	
	/**
	* Draws a quadratic curve from the current drawing point to (x,y) using the control point (cpx,cpy).  For detailed information, read the <a href="http://www.whatwg.org/specs/web-apps/current-work/multipage/the-canvas-element.html#complex-shapes-(paths)">whatwg spec</a>.
	* @param cpx
	* @param cpy
	* @param x
	* @param y
	**/
	p.quadraticCurveTo = function(cpx, cpy, x, y) {
		this._dirty = this._active = true;
		this._activeInstructions += "c.quadraticCurveTo("+cpx+","+cpy+","+x+","+y+");";
		return this;
	}
	
	/**
	* Draws a bezier curve from the current drawing point to (x,y) using the control points (cp1x,cp1y) and (cp2x,cp2y).  For detailed information, read the <a href="http://www.whatwg.org/specs/web-apps/current-work/multipage/the-canvas-element.html#complex-shapes-(paths)">whatwg spec</a>.
	* @param cp1x
	* @param cp1y
	* @param cp2x
	* @param cp2y
	* @param x
	* @param y
	**/
	p.bezierCurveTo = function(cp1x, cp1y, cp2x, cp2y, x, y) {
		this._dirty = this._active = true;
		this._activeInstructions += "c.bezierCurveTo("+cp1x+","+cp1y+","+cp2x+","+cp2y+","+x+","+y+");";
		return this;
	}
	
	
	/**
	* Draws a rectangle at (x,y) with the specified width and height using the current fill and/or stroke.  For detailed information, read the <a href="http://www.whatwg.org/specs/web-apps/current-work/multipage/the-canvas-element.html#complex-shapes-(paths)">whatwg spec</a>.
	* @param cpx
	* @param cpy
	* @param x
	* @param y
	**/
	p.rect = function(x, y, w, h) {
		this._dirty = this._active = true;
		this._activeInstructions += "c.rect("+x+","+y+","+w+","+h+");";
		return this;
	}
	
	/**
	* Closes the current path, effectively drawing a line from the current drawing point to the first drawing point specified since the fill or stroke was last set.
	**/
	p.closePath = function() {
		this._activeInstructions += "c.closePath();";
	}
	
	
// public methods that roughly map to Flash graphics APIs:
	/**
	* Clears all drawing instructions, effectively reseting this Graphics instance.
	**/
	p.clear = function() {
		this._instructions = this._oldInstructions = this._activeInstructions = this._strokeStyleInstructions = "";
		this._strokeInstructions = this._fillInstructions = null;
		this._active = this._dirty = false;
		this._assets = [];
		return this;
	}
	
	/**
	* Begins a fill with the specified color. This ends the current subpath.
	* @param color A CSS compatible color value (ex. "#FF0000" or "rgba(255,0,0,0.5)"). Setting to null will result in no fill.
	**/
	p.beginFill = function(color) {
		if (this._active) { this._newPath(); }
		if (color == null) { this._fillInstructions = null; }
		else { this._fillInstructions = "c.fillStyle='"+color+"';"; }
		return this;
	}
	
	/**
	* Begins a linear gradient fill defined by the line (x0,y0) to (x1,y1). This ends the current subpath. For example, the following code defines a black to white vertical gradient ranging from 20px to 120px, and draws a square to display it:<br/>
	* myGraphics.beginLinearGradientFill(["#000","#FFF"], [0,1], 0, 20, 0, 120).drawRect(20,20,120,120);
	* @param colors An array of CSS compatible color values. For example, ["#F00","#00F"] would define a gradient drawing from red to blue.
	* @param ratios An array of gradient positions which correspond to the colors. For example, [0.1,0.9] would draw the first color to 10% then interpolating to the second color at 90%.
	* @param x0 The position of the first point defining the line that defines the gradient direction and size.
	* @param y0 The position of the first point defining the line that defines the gradient direction and size.
	* @param x1 The position of the second point defining the line that defines the gradient direction and size.
	* @param y1 The position of the second point defining the line that defines the gradient direction and size.
	**/
	p.beginLinearGradientFill = function(colors, ratios, x0, y0, x1, y1) {
		if (this._active) { this._newPath(); }
		this._fillInstructions = "o=c.createLinearGradient("+x0+","+y0+","+x1+","+y1+");";
		var l = colors.length;
		for (var i=0; i<l; i++) {
			this._fillInstructions += "o.addColorStop("+ratios[i]+",'"+colors[i]+"');";
		}
		this._fillInstructions += "c.fillStyle=o;"
		return this;
	}
	
	/**
	* Begins a radial gradient fill. This ends the current subpath. For example, the following code defines a red to blue radial gradient centered at (100,100), with a radius of 50, and draws a circle to display it:<br/>
	* myGraphics.beginRadialGradientFill(["#F00","#00F"], [0,1], 100, 100, 0, 100, 100, 50).drawCircle(100, 100, 50);
	* @param colors An array of CSS compatible color values. For example, ["#F00","#00F"] would define a gradient drawing from red to blue.
	* @param ratios An array of gradient positions which correspond to the colors. For example, [0.1,0.9] would draw the first color to 10% then interpolating to the second color at 90%.
	* @param x0 Center position of the inner circle that defines the gradient.
	* @param y0 Center position of the inner circle that defines the gradient.
	* @param r0 Radius of the inner circle that defines the gradient.
	* @param x1 Center position of the outer circle that defines the gradient.
	* @param y1 Center position of the outer circle that defines the gradient.
	* @param r1 Radius of the outer circle that defines the gradient.
	**/
	p.beginRadialGradientFill = function(colors, ratios, x0, y0, r0, x1, y1, r1) {
		if (this._active) { this._newPath(); }
		this._fillInstructions = "o=c.createRadialGradient("+x0+","+y0+","+r0+","+x1+","+y1+","+r1+");";
		var l = colors.length;
		for (var i=0; i<l; i++) {
			this._fillInstructions += "o.addColorStop("+ratios[i]+",'"+colors[i]+"');";
		}
		this._fillInstructions += "c.fillStyle=o;"
		return this;
	}
	
	/**
	* Begins a pattern fill using the specified image. This ends the current subpath.
	* @param image The Image, Canvas, or Video object to use as the pattern.
	* @param repetition Optional. Indicates whether to repeat the image in the fill area. One of repeat, repeat-x, repeat-y, or no-repeat. Defaults to "repeat".
	**/
	p.beginBitmapFill = function(image, repetition) {
		if (this._active) { this._newPath(); }
		repetition = repetition || "";
		var l = this._assets.length;
		this._assets[l] = image;
		this._fillInstructions = "c.fillStyle=c.createPattern(a["+l+"],'"+repetition+"');";
		return this;
	}
	
	/**
	* Ends the current subpath, and begins a new one with no fill. Functionally identical to beginFill(null).
	**/
	p.endFill = function() {
		this.beginFill(null);
		return this;
	}
	
	/**
	* Sets the stroke style for the current subpath. Like all drawing methods, this can be chained, so you can define the stroke style and color in a single line of code like so:
	* myGraphics.setStrokeStyle(8,"round").beginStroke("#F00");
	* @param thickness The width of the stroke.
	* @param caps Optional. Indicates the type of caps to use at the end of lines. One of butt, round, or square. Defaults to "butt".
	* @param joints Optional. Specifies the type of joints that should be used where two lines meet. One of bevel, round, or miter. Defaults to "miter".
	* @param miter Optional. If joints is set to "miter", then you can specify a miter limit ratio which controls at what point a mitered joint will be clipped.
	**/
	p.setStrokeStyle = function(thickness, caps, joints, miterLimit) {
		if (this._active) { this._newPath(); }
		this._strokeStyleInstructions = "c.lineWidth="+(thickness != null ? thickness : "1")+";"
			+ "c.lineCap='" + (caps ? caps : "butt") +"';"
			+ "c.lineJoin='" + (joints ? joints : "miter") +"';"
			+ "c.miterLimit="+ (miterLimit ? miterLimit : "10")+";";
		return this;
	}
	
	/**
	* Begins a stroke with the specified color. This ends the current subpath.
	* @param color A CSS compatible color value (ex. "#FF0000" or "rgba(255,0,0,0.5)"). Setting to null will result in no stroke.
	**/
	p.beginStroke = function(color) {
		if (this._active) { this._newPath(); }
		this._strokeInstructions = color ? "c.strokeStyle='"+color+"';" : null;
		return this;
	}
	
	/**
	* Begins a linear gradient stroke defined by the line (x0,y0) to (x1,y1). This ends the current subpath. For example, the following code defines a black to white vertical gradient ranging from 20px to 120px, and draws a square to display it:<br/>
	* myGraphics.setStrokeStyle(10).beginLinearGradientStroke(["#000","#FFF"], [0,1], 0, 20, 0, 120).drawRect(20,20,120,120);
	* @param colors An array of CSS compatible color values. For example, ["#F00","#00F"] would define a gradient drawing from red to blue.
	* @param ratios An array of gradient positions which correspond to the colors. For example, [0.1,0.9] would draw the first color to 10% then interpolating to the second color at 90%.
	* @param x0 The position of the first point defining the line that defines the gradient direction and size.
	* @param y0 The position of the first point defining the line that defines the gradient direction and size.
	* @param x1 The position of the second point defining the line that defines the gradient direction and size.
	* @param y1 The position of the second point defining the line that defines the gradient direction and size.
	**/
	p.beginLinearGradientStroke = function(colors, ratios, x0, y0, x1, y1) {
		if (this._active) { this._newPath(); }
		this._strokeInstructions = "o=c.createLinearGradient("+x0+","+y0+","+x1+","+y1+");";
		var l = colors.length;
		for (var i=0; i<l; i++) {
			this._strokeInstructions += "o.addColorStop("+ratios[i]+",'"+colors[i]+"');";
		}
		this._strokeInstructions += "c.strokeStyle=o;"
		return this;
	}
	
	
	/**
	* Begins a radial gradient stroke. This ends the current subpath. For example, the following code defines a red to blue radial gradient centered at (100,100), with a radius of 50, and draws a rectangle to display it:<br/>
	* myGraphics.setStrokeStyle(10).beginRadialGradientStroke(["#F00","#00F"], [0,1], 100, 100, 0, 100, 100, 50).drawRect(50,90,150,110);
	* @param colors An array of CSS compatible color values. For example, ["#F00","#00F"] would define a gradient drawing from red to blue.
	* @param ratios An array of gradient positions which correspond to the colors. For example, [0.1,0.9] would draw the first color to 10% then interpolating to the second color at 90%, then draw the second color to 100%.
	* @param x0 Center position of the inner circle that defines the gradient.
	* @param y0 Center position of the inner circle that defines the gradient.
	* @param r0 Radius of the inner circle that defines the gradient.
	* @param x1 Center position of the outer circle that defines the gradient.
	* @param y1 Center position of the outer circle that defines the gradient.
	* @param r1 Radius of the outer circle that defines the gradient.
	**/
	p.beginRadialGradientStroke = function(colors, ratios, x0, y0, r0, x1, y1, r1) {
		if (this._active) { this._newPath(); }
		this._strokeInstructions = "o=c.createRadialGradient("+x0+","+y0+","+r0+","+x1+","+y1+","+r1+");";
		var l = colors.length;
		for (var i=0; i<l; i++) {
			this._strokeInstructions += "o.addColorStop("+ratios[i]+",'"+colors[i]+"');";
		}
		this._strokeInstructions += "c.strokeStyle=o;"
		return this;
	}
	
	/**
	* Begins a pattern fill using the specified image. This ends the current subpath.
	* @param image The Image, Canvas, or Video object to use as the pattern.
	* @param repetition Optional. Indicates whether to repeat the image in the fill area. One of repeat, repeat-x, repeat-y, or no-repeat. Defaults to "repeat".
	**/
	p.beginBitmapStroke = function(image, repetition) {
		if (this._active) { this._newPath(); }
		repetition = repetition || "";
		var l = this._assets.length;
		this._assets[l] = image;
		this._strokeInstructions = "c.strokeStyle=c.createPattern(a["+l+"],'"+repetition+"');";
		return this;
	}
	
	
	/**
	* Ends the current subpath, and begins a new one with no stroke. Functionally identical to beginStroke(null).
	**/
	p.endStroke = function() {
		this.beginStroke(null);
		return this;
	}
	
	/**
	* Maps the familiar ActionScript curveTo() method to the functionally similar quatraticCurveTo() method.
	**/
	p.curveTo = p.quadraticCurveTo;
	
	/**
	* Maps the familiar ActionScript drawRect() method to the functionally similar rect() method.
	**/
	p.drawRect = p.rect;
	
	/**
	* Draws a rounded rectangle with all corners with the specified radius.
	* @param x
	* @param y
	* @param w
	* @param h
	* @param radius Corner radius.
	**/
	p.drawRoundRect = function(x, y, w, h, radius) {
		this.drawRoundRectComplex(x, y, w, h, radius, radius, radius, radius);
		return this;
	}
	
	/**
	* Draws a rounded rectangle with different corner radiuses.
	* @param x
	* @param y
	* @param w
	* @param h
	* @param radiusTL Top left corner radius.
	* @param radiusTR Top right corner radius.
	* @param radiusBR Bottom right corner radius.
	* @param radiusBL Bottom left corner radius.
	**/
	p.drawRoundRectComplex = function(x, y, w, h, radiusTL, radiusTR, radiusBR, radiusBL) {
		this._dirty = this._active = true;
		this._activeInstructions += "c.moveTo("+(x+radiusTL)+","+y+");c.lineTo("+(x+w-radiusTR)+","+y+");"
			+ "c.arc("+(x+w-radiusTR)+","+(y+radiusTR)+","+radiusTR+","+(-Math.PI/2)+",0,false) ;"
			+ "c.lineTo("+(x+w)+","+(y+h-radiusBR)+");"
			+ "c.arc("+(x+w-radiusBR)+","+(y+h-radiusBR)+","+radiusBR+",0,"+(Math.PI/2)+",false) ;"
			+ "c.lineTo("+(x+radiusBL)+","+(y+h)+");"
			+ "c.arc("+(x+radiusBL)+","+(y+h-radiusBL)+","+radiusBL+","+(Math.PI/2)+","+Math.PI+",false) ;"
			+ "c.lineTo("+x+","+(y+radiusTL)+");"
			+ "c.arc("+(x+radiusTL)+","+(y+radiusTL)+","+radiusTL+","+Math.PI+","+Math.PI*3/2+",false) ;";
		return this;
	} 
	
	/**
	* Draws a circle with the specified radius at (x,y).
	* @param x
	* @param y
	* @param radius
	**/
	p.drawCircle = function(x, y, radius) {
		this.arc(x, y, radius, 0, Math.PI*2);
		return this;
	}
	
	/**
	* Draws an ellipse (oval).
	* @param x
	* @param y
	* @param w
	* @param h
	**/
	p.drawEllipse = function(x, y, w, h) {
		this._dirty = this._active = true;
			
		var k = 0.5522848;
		var ox = (w / 2) * k;
		var oy = (h / 2) * k;
		var xe = x + w;
		var ye = y + h;
		var xm = x + w / 2;
		var ym = y + h / 2;
			
		this._activeInstructions += "c.moveTo("+x+","+ym+");"
			+ "c.bezierCurveTo("+x+","+(ym-oy)+","+(xm-ox)+","+y+","+xm+","+y+");"
			+ "c.bezierCurveTo("+(xm+ox)+","+y+","+xe+","+(ym-oy)+","+xe+","+ym+");"
			+ "c.bezierCurveTo("+xe+","+(ym+oy)+","+(xm+ox)+","+ye+","+xm+","+ye+");"
			+ "c.bezierCurveTo("+(xm-ox)+","+ye+","+x+","+(ym+oy)+","+x+","+ym+");";
		return this;
	}
	
	
	p.clone = function() {
		var o = new Graphics(this._instructions);
		o._activeIntructions = this._activeInstructions;
		o._oldInstructions = this._oldInstructions;
		o._fillInstructions = this._fillInstructions;
		o._strokeInstructions = this._strokeInstructions;
		o._strokeStyleInstructions = this._strokeStyleInstructions;
		o._active = this._active;
		o._dirty = this._dirty;
		o._assets = this._assets;
		return o;
	}
		
	p.toString = function() {
		return "[Graphics]";
	}
	
// GDS: clip?, isPointInPath?
	
	
// private methods:
	p._updateInstructions = function() {
		this._instructions = this._oldInstructions+"c.beginPath();";
		 
		if (this._fillInstructions) { this._instructions += this._fillInstructions; }
		if (this._strokeInstructions) { this._instructions += this._strokeInstructions+this._strokeStyleInstructions; }
		
		this._instructions += this._activeInstructions;
		
		if (this._fillInstructions) { this._instructions += "c.fill();"; }
		if (this._strokeInstructions) { this._instructions += "c.stroke();"; }
		
		//this._instructions += "c.closePath();"
	}
	
	p._newPath = function() {
		if (this._dirty) { this._updateInstructions(); }
		this._oldInstructions = this._instructions;
		this._activeInstructions = "";
		this._active = this._dirty = false;
	}

window.Graphics = Graphics;
}(window));