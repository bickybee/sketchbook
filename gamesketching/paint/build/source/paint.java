import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import org.dyn4j.dynamics.Body; 
import codeanticode.tablet.*; 
import controlP5.*; 
import point2line.*; 
import java.awt.geom.*; 
import java.util.List; 
import java.awt.geom.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class paint extends PApplet {







//canvas stuff
Tablet tablet;
Stroke currentStroke;
ArrayList<Point> currentPoints;
ArrayList<Stroke> allStrokes;
int currentColour;
int bg;
StrokeGroup selectedStrokes;
//layers, but later i'll make it an ArrayList where you can make as many as you want...

//
Mode penMode;
boolean translating;
boolean penIsDown;
float penSpeed;
//
float xOffset;
float yOffset;
//
float sx1, sy1, sx2, sy2;

//GUI stuff 
ControlP5 gui;
ColorPicker cp;
int buttonW = 60;
int buttonH = 40;
Button undoBtn;
RadioButton modeRadio;
RadioButton colourRadio;
RadioButton layerRadio;

//any initialization goes here
public void setup() {
    fullScreen(2); //fullscreen on second screen (tablet)
    
    //buttons activate when you add them.... lame
    gui = new ControlP5(this);
    undoBtn = gui.addButton("undo")
        .setPosition(0,0)
        .setSize(buttonW, buttonH)
        .activateBy(ControlP5.PRESSED);
    colourRadio = gui.addRadioButton("colour")
                .setPosition(0,buttonH+10)
                .setSize(buttonW, buttonH)
                .setColorForeground(color(120))
                .setColorActive(color(200))
                .setColorLabel(color(102))
                .setItemsPerRow(1)
                .setSpacingColumn(0)
                .addItem("black",0)
                .addItem("red",color(255,0,0))
                .addItem("blue",color(0,0,255))
                .addItem("green",color(0,255,0));
    colourRadio.getItem("black").setState(true); //default
    modeRadio = gui.addRadioButton("mode")
                .setPosition(0,buttonH*5+20)
                .setSize(buttonW, buttonH)
                .setColorForeground(color(120))
                .setColorActive(color(200))
                .setColorLabel(color(102))
                .setItemsPerRow(1)
                .setSpacingColumn(0)
                .addItem("draw",1)
                .addItem("erase",2)
                .addItem("select",3)
                .addItem("box select",4);
    modeRadio.getItem("draw").setState(true); //default
    layerRadio = gui.addRadioButton("layer")
                .setPosition(0,buttonH*9+30)
                .setSize(buttonW, buttonH)
                .setColorForeground(color(120))
                .setColorActive(color(200))
                .setColorLabel(color(102))
                .setItemsPerRow(1)
                .setSpacingColumn(0)
                .addItem("layer1",1)
                .addItem("layer2",2)
                .addItem("layer3",3);
    //instantiate stuff after adding buttons!
    tablet = new Tablet(this);
    bg = color(255);
    currentColour = color(0,0,0);
    currentStroke = new Stroke(currentColour);
    allStrokes = new ArrayList<Stroke>();
    selectedStrokes = new StrokeGroup();
    //
    penIsDown = false;
    penMode = Mode.DRAW;
    translating = false;
    //
    background(bg);
}

//GUI handler
public void controlEvent (ControlEvent e){

    //UNDO
    if (e.isFrom(undoBtn)){
        if (allStrokes.size() != 0){
            undoStroke();
        }
    }

    //MODES
    else if (e.isFrom(modeRadio)){
        switch ((int)e.getValue()){

            //DRAW
            case 1:
                clearSelection();
                reDraw();
                penMode = Mode.DRAW;
                break;

            //ERASE
            case 2:
                reDraw();
                //if something is selected, erase that, while remaining in select mode
                if (selectedStrokes.getMembers().size()!=0){
                    modeRadio.getItem("erase").setState(false);
                    modeRadio.getItem("select").setState(true);
                    eraseSelection();
                    reDraw();
                }
                //otherwise just switch to erase mode
                else penMode = Mode.ERASE;
                break;

            //SELECT
            case 3:
                penMode = Mode.SELECT;
                break;

            //BOXSELECT
            case 4:
                penMode = Mode.BOXSELECT;
                break;

            default:
                break;
        }
    }

    //COLOURS
    else{
        currentColour = (int)e.getValue();
        stroke(currentColour);
        if (selectedStrokes.getMembers().size()!=0){
            for (Stroke s: selectedStrokes.getMembers()){
                s.setColour(currentColour);
            }
            reDraw();
        }
    }
}

//drawing loop
//basically the tablet-input handler
public void draw() {
     
    if (tablet.isLeftDown()&&mouseX>buttonW) penDown();
    else if (!tablet.isLeftDown() && penIsDown) penUp();
    else penHover();

    penSpeed = abs(mouseX-pmouseX) + abs(mouseY-pmouseY);
    tablet.saveState();
}

public void penDown(){

    //ERASE: remove strokes that intersect pen
    if (penMode==Mode.ERASE || (tablet.getPenKind()==Tablet.ERASER && penMode==Mode.DRAW)){       
        for (Stroke stroke: allStrokes){
            if (stroke.intersects(mouseX, mouseY, pmouseX, pmouseY)){
                allStrokes.remove(stroke);
                reDraw();
                break;
            }
        }
    }

    //DRAW: create strokes!
    else if (penMode==Mode.DRAW){

        //just pressed: instantiate new stroke
        if (!penIsDown){
            penIsDown = true;
            currentStroke = new Stroke(currentColour);
            stroke(currentColour);
        }

        if (currentStroke.addPoint(new Point(mouseX, mouseY, 5*tablet.getPressure()))){
            reDraw();
            currentStroke.draw();
        }
        //currentStroke.draw(tablet, mouseX, mouseY, pmouseX, pmouseY);

    }

    //SELECT: select strokes that intersect pen
    //BOX SELECT: create box that will select strokes on penUp
    else if (penMode==Mode.SELECT||penMode==Mode.BOXSELECT){
        
        //if eraser is put down, erase current selection
        if (tablet.getPenKind()==Tablet.ERASER) eraseSelection();

        //translate: move selection along with pen
        else if (translating){
            xOffset = mouseX-pmouseX;
            yOffset = mouseY-pmouseY;
            selectedStrokes.translate(xOffset, yOffset);
            reDraw();
        }

        //just pressed: start new selection
        else if (!penIsDown){
            penIsDown = true;
            clearSelection();
            reDraw();
            if (penMode==Mode.BOXSELECT){
                sx1 = mouseX;
                sy1 = mouseY;
            }
        }

        //dragging: check for strokes that intersect and select them
        else if (penMode==Mode.SELECT){
            for (Stroke stroke: allStrokes){
                if (!stroke.isSelected()&&stroke.intersects(mouseX, mouseY, pmouseX,pmouseY)){
                    stroke.select();
                    selectedStrokes.addMember(stroke);
                    reDraw();
                    break;
                }
            }
        }

        //dragging: create box
        else if (penMode==Mode.BOXSELECT){
            sx2 = mouseX;
            sy2 = mouseY;
            reDraw();
            stroke(102);
            line(sx1,sy1,sx2,sy1);
            line(sx2,sy1,sx2,sy2);
            line(sx2,sy2,sx1,sy2);
            line(sx1,sy2,sx1,sy1);
        }
    }

}

public void penUp(){

    //DRAW: save finished stroke
    if (penMode==Mode.DRAW){
        Stroke finishedStroke = new Stroke(currentColour);
        for (Point p: currentStroke.points){
            finishedStroke.addPoint(new Point(p.getX(), p.getY(), p.getWeight()));
        }
        finishedStroke.setBounds();
        allStrokes.add(finishedStroke); //add stroke

        //TESTING IF HULL THING WORKS
        Stroke hullStroke = new Stroke(color(255,0,255));
        Point[] strokePoints = finishedStroke.getPoints().toArray(new Point[finishedStroke.getPoints().size()]);
        GiftWrap gw = new GiftWrap();
        Point[] hull = gw.generate(strokePoints);
        for (Point p: hull){
            hullStroke.addPoint(p);
        }
        allStrokes.add(hullStroke);
        //done test (it works!)
    }

    //BOXSELECT: select all strokes whose **BBs** fall within created box
    //(should change this later to be more precise than BBs)
    if (penMode==Mode.BOXSELECT){
        for (Stroke s: allStrokes){
            if (!s.isSelected()&&s.boundsIntersectRect(min(sx1,sx2), min(sy1,sy2), max(sx1,sx2), max(sy1,sy2))){
                s.select();
                selectedStrokes.addMember(s);
            }
        }
        reDraw();
    }

    penIsDown = false;

}

public void penHover(){

    //SELECT or TRANSLATE: distinguish between modes by checking if pen is within current selection bounds
    //gets real gross in here, ungross it
    if (penMode == Mode.SELECT || penMode == Mode.BOXSELECT){
        if (selectedStrokes.boundsContain(mouseX, mouseY)){
            cursor(CROSS);
            translating = true;
        }
        else if (translating){
            cursor(ARROW);
            translating = false;
        } 
    }
}


public void undoStroke(){
    allStrokes.remove(allStrokes.size()-1);
    reDraw();
}

public void drawAllStrokes(){
    selectedStrokes.drawBounds();
    for (Stroke selected: selectedStrokes.getMembers()){
        selected.drawSelected();
    }
    for (Stroke stroke: allStrokes){
        stroke.draw();
    }
}

public void clearSelection(){
    for (Stroke s: allStrokes){
        if (s.isSelected()) s.deselect();
    }
    selectedStrokes = new StrokeGroup();
}

public void eraseSelection(){
    for (Stroke s: selectedStrokes.getMembers()){
        allStrokes.remove(s); //presumably slow, but it works
    }
    selectedStrokes = new StrokeGroup();
    reDraw();
}

public void reDraw(){
    background(bg);
    drawAllStrokes();
}
/*
 * Copyright (c) 2010-2016 William Bittle  http://www.dyn4j.org/
 * All rights reserved.
 * 
 * Redistribution and use in source and binary forms, with or without modification, are permitted 
 * provided that the following conditions are met:
 * 
 *   * Redistributions of source code must retain the above copyright notice, this list of conditions 
 *     and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright notice, this list of conditions 
 *     and the following disclaimer in the documentation and/or other materials provided with the 
 *     distribution.
 *   * Neither the name of dyn4j nor the names of its contributors may be used to endorse or 
 *     promote products derived from this software without specific prior written permission.
 * 
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR 
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND 
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL 
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER 
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT 
 * OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


class GiftWrap{
	/* (non-Javadoc)
	 * @see org.dyn4j.geometry.hull.HullGenerator#generate(org.dyn4j.geometry.Point[])
	 */

	public Point[] generate(Point[] points) {
		// check for null array
		if (points == null) throw new NullPointerException("null points");
		
		// get the size
		int size = points.length;
		// check the size
		if (size <= 2) return points;
		
		// find the left most point
		double x = Double.MAX_VALUE;
		Point leftMost = null;
		for (int i = 0; i < size; i++) {
			Point p = points[i];
			// check for null points
			if (p == null) throw new NullPointerException("null point");
			// check the x cooridate
			if (p.x < x) {
				x = p.x;
				leftMost = p;
			}
		}
		
		// initialize the hull size to the worst case size
		List<Point> hull = new ArrayList<Point>(size);
		do {
			// add the left most point
			hull.add(leftMost);
			// check all the points to see if anything is more left than the next point
			Point maxLeft = points[0];
			// check if the first point in the array is the leftMost point
			// if so, then we need to choose another point so that the location
			// check performs correctly
			if (maxLeft == leftMost) maxLeft = points[1];
			// loop over the points to find a more left point than the current
			for (int j = 0; j < size; j++) {
				Point t = points[j];
				// don't worry about the points that create the line we are inspecting
				// since we know that they are already the left most
				if (t == maxLeft) continue;
				if (t == leftMost) continue;
				// check the point relative to the current line
				if (getLocation(t, leftMost, maxLeft) < 0.0f) {
					// this point is further left than the current point
					maxLeft = t;
				}
			}
			// set the new leftMost point
			leftMost = maxLeft;
			// loop until we repeat the first leftMost point
		} while (leftMost != hull.get(0));
		
		// copy the list into an array
		Point[] hullPoints = new Point[hull.size()];
		hull.toArray(hullPoints);
		
		// return the array
		return hullPoints;
	}

	public double getLocation(Point point, Point linePoint1, Point linePoint2) {
		return (linePoint2.x - linePoint1.x) * (point.y - linePoint1.y) -
			  (point.x - linePoint1.x) * (linePoint2.y - linePoint1.y);
	}
}
//pen modes
//more to come
class Point{
    
    float x, y, weight;
    boolean remove;


    Point(float x0, float y0){
        x = x0;
        y = y0;
        remove = false;
    }

    Point(float x0, float y0, float w){
        x = x0;
        y = y0;
        weight = w;
        remove = false;
    }

    public void translate(float xOff, float yOff){
        x += xOff;
        y += yOff;
    }
    
    public float getX(){
        return x;
    }
    
    public float getY(){
        return y;
    }

    public float getWeight(){
        return weight;
    }

    public void setRemove(){
        remove = true;
    }

    public boolean shouldRemove(){
        return remove;
    }
}


//------------------------------------------
//stroke class to contain points, color, 
//------------------------------------------
class Stroke{
    ArrayList<Point> points;
    int colour;
    float top, bottom, left, right; //bounding box coordinates
    boolean selected;

    Stroke(int c){
        points = new ArrayList<Point>();
        colour = c;
        top = Float.MAX_VALUE;
        bottom = 0;
        left = Float.MAX_VALUE;
        right = 0;
        selected = false;
    }

    //-------------------------------------
    //METHODS
    //-------------------------------------
    
    public boolean addPoint(Point p){
        if (points.size()==0){
            points.add(p);
            return true;
        }
        else if (!(p.getX() == points.get(points.size()-1).getX() && p.getY() == points.get(points.size()-1).getY())){
            points.add(p);
            return true;
        }
        return false;
    }

    public void removePoint(Point p){
        points.remove(p);
    }

    //draw while creating a stroke
    public void draw(Tablet tab, float newX, float newY, float oldX, float oldY){
        //strokeWeight(tab.getPressure()*5);
        line(newX, newY, oldX, oldY);
    }
    
    //drawing a completed stroke
    public void draw(){
        stroke(colour);
        strokeWeight(2);
        noFill();
        beginShape();
        curveVertex(points.get(0).getX(), points.get(0).getY());
        for (int i = 0; i < points.size(); i++){
            curveVertex(points.get(i).getX(), points.get(i).getY());
        }
        curveVertex(points.get(points.size()-1).getX(), points.get(points.size()-1).getY());
        endShape();
        // for (int i = 1; i < points.size(); i++){
        //     strokeWeight(points.get(i).weight);
        //     line(points.get(i).getX(), points.get(i).getY(), points.get(i-1).getX(), points.get(i-1).getY());;
        // }
    }

    //draw a sort of "highlight" to indicate stroke is selected
    public void drawSelected(){
        stroke(color(200));
        for (int i = 1; i < points.size(); i++){
            //strokeWeight(points.get(i).weight+10);
            line(points.get(i).getX(), points.get(i).getY(), points.get(i-1).getX(), points.get(i-1).getY());;
        }
    }

    public void drawBounds(){
        stroke(102);
        strokeWeight(2);
        line(left, top, right, top);
        line(right, top, right, bottom);
        line(right, bottom, left, bottom);
        line(left, bottom, left, top);
    }

    public void setBounds(){
        for (Point p: points){
            if (p.getX() < left) left = p.getX();
            if (p.getX() > right) right = p.getX();
            if (p.getY() < top) top = p.getY();
            if (p.getY() > bottom) bottom = p.getY();
        }
        //bloat small points?
        bloatSmallBounds(5);
    }

    public void bloatSmallBounds(float minSize){
        float area = (right-left)*(bottom-top);
        if (area<minSize){
            float bloat = minSize-area;
            left -= bloat;
            right += bloat;
            top -= bloat;
            bottom += bloat;
        }
    }

    public boolean boundsContain(int x, int y){
        if (x > left && x < right && y > top && y < bottom) return true;
        else return false;
    }

    public boolean boundsContain(float x, float y){
        if (x > left && x < right && y > top && y < bottom) return true;
        else return false;
    }

    public boolean rectIntersectsLine(float l, float t, float r, float b,
        float x1, float y1, float x2, float y2){
        if (Line2D.linesIntersect(x1,y1,x2,y2,l,t,r,t) ||
            Line2D.linesIntersect(x1,y1,x2,y2,r,t,r,b) ||
            Line2D.linesIntersect(x1,y1,x2,y2,r,b,l,b) ||
            Line2D.linesIntersect(x1,y1,x2,y2,l,b,l,t)){
                return true;
        }
        else return false;
    }

    public boolean boundsIntersectLine(float x1, float y1, float x2, float y2){
        return rectIntersectsLine(left, top, right, bottom, x1,y1,x2,y2);
    }

    //bounds intersect rectangle
    public boolean boundsIntersectRect(float l, float t, float r, float b){
        if (bottom<t || b<top || right<l || r<left) return false;
        else return true;
    }

    //line intersection with stroke
    public boolean intersects(float x1, float y1, float x2, float y2){
        //check if end points are in bounding box, or that it intersects the box
        if (boundsContain(x1, y1)||boundsContain(x2, y2)||boundsIntersectLine(x1,y1,x2,y2)){
            //for each pair of points, create line segments and check intersections
            for (int i=1; i<points.size(); i++){
                if (Line2D.linesIntersect(x1,y1,x2,y2,points.get(i).getX(),
                    points.get(i).getY(), points.get(i-1).getX(), points.get(i-1).getY())){
                    return true;
                }
            }
        }
        return false;
    }

    // //lol
    // //give pen an AABB depending on SPEED!
    // boolean intersectsPen(float x, float y, float speed){
    //     rect(x-speed/2, y-speed/2, x+speed/2, y+speed/2);
    //     for (int i=1; i<points.size(); i++){
    //         if (rectIntersectsLine(x-speed/2, y-speed/2, x+speed/2, y+speed/2,points.get(i).getX(),
    //                 points.get(i).getY(), points.get(i-1).getX(), points.get(i-1).getY())){
    //             return true;
    //         }
    //     }
    //     return false;
    // }


    public void translate(float xOff, float yOff){
        left += xOff;
        right += xOff;
        top += yOff;
        bottom += yOff;
        for (Point p: points){
            p.translate(xOff, yOff);
        }
    }

    public void simplify(){
        // int pointsAhead = 1;
        // for (int i =0; i<points.size(); i++){
        //     if (!points.get(i+pointsAhead).shouldRemove() && points.get(i).distanceFrom(points.get(i+pointsAhead))>5){
        //         points.get(i+pointsAhead).setRemove();
        //     }
        // }
    }

// --------------------------------------
// GETTERS AND SETTERS
// --------------------------------------

 public ArrayList<Point> getPoints() {
        return points;
    }

    public void setPoints(ArrayList<Point> points) {
        this.points = points;
    }

    public int getColour() {
        return colour;
    }

    public void setColour(int colour) {
        this.colour = colour;
    }

    public float getTop() {
        return top;
    }

    public void setTop(float top) {
        this.top = top;
    }

    public float getBottom() {
        return bottom;
    }

    public void setBottom(float bottom) {
        this.bottom = bottom;
    }

    public float getLeft() {
        return left;
    }

    public void setLeft(float left) {
        this.left = left;
    }

    public float getRight() {
        return right;
    }

    public void setRight(float right) {
        this.right = right;
    }

    public boolean isSelected() {
        return selected;
    }

    public void select(){
        selected = true;
    }

    public void deselect(){
        selected = false;
    }

}
class StrokeGroup{

	ArrayList<Stroke> members;
	float top, bottom, left, right; //group bounding box
	boolean selected;

	StrokeGroup(){
		members = new ArrayList<Stroke>();
		selected = true;
		top = Float.MAX_VALUE;
        bottom = 0;
        left = Float.MAX_VALUE;
        right = 0;
	}

	public void addMember(Stroke s){
		members.add(s);
		if (s.left < left) left = s.left;
        if (s.right > right) right = s.right;
        if (s.top < top) top = s.top;
        if (s.bottom > bottom) bottom = s.bottom;
	}

	public boolean boundsContain(float x, float y){
        if (x > left && x < right && y > top && y < bottom) return true;
        else return false;
    }

    public void drawBounds(){
        stroke(102);
        strokeWeight(2);
        line(left, top, right, top);
        line(right, top, right, bottom);
        line(right, bottom, left, bottom);
        line(left, bottom, left, top);
    }

    public void translate(float xOff, float yOff){
    	left += xOff;
    	right += xOff;
    	top += yOff;
    	bottom += yOff;
    	for (int i = 0; i < members.size(); i++){
    		members.get(i).translate(xOff, yOff);
		}
    }

// --------------------------------------
// GETTERS AND SETTERS
// --------------------------------------

	public ArrayList<Stroke> getMembers() {
		return members;
	}

	public void setMembers(ArrayList<Stroke> members) {
		this.members = members;
	}

	public float getTop() {
		return top;
	}

	public void setTop(float top) {
		this.top = top;
	}

	public float getBottom() {
		return bottom;
	}

	public void setBottom(float bottom) {
		this.bottom = bottom;
	}

	public float getLeft() {
		return left;
	}

	public void setLeft(float left) {
		this.left = left;
	}

	public float getRight() {
		return right;
	}

	public void setRight(float right) {
		this.right = right;
	}

	public boolean isSelected() {
		return selected;
	}

	public void setSelected(boolean selected) {
		this.selected = selected;
	}

}
    static public void main(String[] passedArgs) {
        String[] appletArgs = new String[] { "paint" };
        if (passedArgs != null) {
          PApplet.main(concat(appletArgs, passedArgs));
        } else {
          PApplet.main(appletArgs);
        }
    }
}
