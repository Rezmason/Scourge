/**
* Shape by Grant Skinner. Dec 5, 2010
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
* Constructs a new Shape instance.
* @param instructions Optional. The vector drawing instruction that this Shape will use. See the instructions property for information.
* @class A Shape instance encapsulates a set of vector drawing instructions so they can be rendered to the stage. All of the current drawing methods map directly to canvas 2D context APIs.<br/> NOTE: This class is incomplete. I will be adding shortcut methods (ex. drawCircle, drawRoundRect, etc), and possibly changing the inner workings. It also doesn't clean up fill or stroke styles yet, so they can bleed into subsequent Shapes. You've been warned. :)
* @augments DisplayObject
**/
function Shape(instructions) {
  this.init(instructions);
}
var p = Shape.prototype = new DisplayObject();

// public properties:
	/** A string containing all of the canvas drawing instructions encapsulated by this Shape. These will be evaluated using a ctx variable for the current canvas 2D context. For example instructions="ctx.fillStyle='#F00';ctx.fillRect(-75,-75,150,150);" would draw a 150x150 red square.  **/
	p.instructions = null;
	
// constructor:
	/** @private **/
	p._init = p.init;
	/** @private **/
	p.init = function(instructions) {
		this._init();
		this.instructions = instructions || "";
	}
	
// public methods:
	p._draw = p.draw;
	p.draw = function(ctx,ignoreCache) {
		if (this.cacheCanvas == null && (this.instructions == null || this.instructions.length < 1)) { return false; }
		if (!this._draw(ctx,ignoreCache)) { return false; }
		var type = typeof(this.instructions);
		if (type == "function") {
			this.instructions(ctx);
		} else if (type == "string") {
			eval(this.instructions);
		}
	}
	
	/**
	* Clears all drawing instructions.
	**/
	p.clear = function() {
		this.instructions = "";
	}
	
	p.beginPath = function() { this.instructions += "ctx.beginPath();"; }
	p.closePath = function() { this.instructions += "ctx.closePath();"; }
	p.moveTo = function(x,y) { this.instructions += "ctx.moveTo("+x+","+y+");"; }
	p.lineTo = function(x,y) { this.instructions += "ctx.lineTo("+x+","+y+");"; }
	p.quadraticCurveTo = function(cpx,cpy,x,y) { this.instructions += "ctx.quadraticCurveTo("+cpx+","+cpy+","+x+","+y+");"; }
	p.bezierCurveTo = function(cpx1,cpy1,cpx2,cpy2,x,y) { this.instructions += "ctx.bezierCurveTo("+cpx1+","+cpy1+","+cpx2+","+cpy2+","+x+","+y+");"; }
	p.arcTo = function(x1,y1,x2,y2,radius) { this.instructions += "ctx.arcTo("+x1+","+y1+","+x2+","+y2+","+radius+");"; }
	p.rect = function(x,y,w,h) { this.instructions += "ctx.rect("+x+","+y+","+w+","+h+");"; }
	p.arc = function(x,y,radius,startAngle,endAngle,anticlockwise) { this.instructions += "ctx.arc("+x+","+y+","+startAngle+","+endAngle+","+anticlockwise+");"; }
	p.fill = function() { this.instructions += "ctx.fill();"; }
	p.stroke = function() { this.instructions += "ctx.stroke();"; }
	p.clip = function() { this.instructions += "ctx.clip();"; } // ?
	p.fillRect = function(x,y,w,h) { this.instructions += "ctx.fillRect("+x+","+y+","+w+","+h+");"; }
	p.strokeRect = function(x,y,w,h) { this.instructions += "ctx.strokeRect("+x+","+y+","+w+","+h+");"; }
	p.setFillStyle = function(value) { this.instructions += "ctx.fillStyle='"+value+"';"; }
	p.setStrokeStyle = function(value) { this.instructions += "ctx.strokeStyle='"+value+"';"; }
	p.setLineWidth = function(value) { this.instructions += "ctx.lineWidth="+value+";"; }
	p.setLineCap = function(value) { this.instructions += "ctx.lineCap='"+value+"';"; }
	
	p.clone = function() {
		var o = new Shape(this.instructions);
		this.cloneProps(o);
		return o;
	}
		
	p.toString = function() {
		return "[Shape (name="+  this.name +")]";
	}
	
// TO ADD:
	// create gradient and radial gradient
	/*
	gradient . addColorStop(offset, color)
	
	gradient = context . createLinearGradient(x0, y0, x1, y1)
	
	gradient = context . createRadialGradient(x0, y0, r0, x1, y1, r1)
	*/
	// line styles
	/*
	
	context . lineJoin [ = value ]
	
	context . miterLimit [ = value ]
	*/
	/*
	drawCircle
	drawElipse
	drawRect
	drawSquare
	drawRoundRect
	drawRoundRectComplex
	drawArc
	*/

window.Shape = Shape;
}(window));