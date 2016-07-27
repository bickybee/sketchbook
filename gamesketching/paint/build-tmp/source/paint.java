import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import com.goebl.simplify.*; 
import codeanticode.tablet.*; 
import controlP5.*; 
import java.awt.geom.*; 
import fisica.*; 
import fisica.*; 
import java.util.List; 
import org.dyn4j.*; 
import org.dyn4j.geometry.*; 
import org.dyn4j.geometry.decompose.*; 
import java.awt.geom.*; 
import java.util.Arrays; 
import java.util.*; 
import fisica.*; 

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
ArrayList<Point> currentStroke;
ArrayList<Stroke> allStrokes;
int currentColour;
int bg;
StrokeGroup selectedStrokes;

//penStuff
Mode mode;
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
Button objBtn;
Button playBtn;
RadioButton penRadio;
RadioButton colourRadio;
RadioButton modeRadio;
boolean playing;

//GAME STUFF!!!!!!!
ArrayList<Entity> entities;
int currentID;

FWorld world;
boolean up, down, left, right;


//any initialization goes here
public void setup() {
     //fullscreen on second screen (tablet)
    //controlP5 setup
    gui = new ControlP5(this);

    undoBtn = gui.addButton("undo")
        .setPosition(0,0)
        .setSize(buttonW, buttonH)
        .activateBy(ControlP5.PRESSED);

    objBtn = gui.addButton("gameObj")
        .setPosition(0,buttonH)
        .setSize(buttonW, buttonH)
        .activateBy(ControlP5.PRESSED);

    colourRadio = gui.addRadioButton("colour")
                .setPosition(0,buttonH*2+10)
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

    penRadio = gui.addRadioButton("pens")
                .setPosition(0,buttonH*6+20)
                .setSize(buttonW, buttonH)
                .setColorForeground(color(120))
                .setColorActive(color(200))
                .setColorLabel(color(102))
                .setItemsPerRow(1)
                .setSpacingColumn(0)
                .addItem("pen",1)
                .addItem("eraser",2)
                .addItem("select",3)
                .addItem("box select",4);
    penRadio.getItem("pen").setState(true); //default

    modeRadio = gui.addRadioButton("mode")
                .setPosition(0,buttonH*10+30)
                .setSize(buttonW, buttonH)
                .setColorForeground(color(120))
                .setColorActive(color(200))
                .setColorLabel(color(102))
                .setItemsPerRow(1)
                .setSpacingColumn(0)
                .addItem("draw",1)
                .addItem("play",2);
    modeRadio.getItem("draw").setState(true);

    //
    tablet = new Tablet(this);
    bg = color(255);
    currentColour = color(0,0,0);
    currentStroke = new ArrayList<Point>();
    allStrokes = new ArrayList<Stroke>();
    selectedStrokes = new StrokeGroup();
    //
    penIsDown = false;
    mode = Mode.PEN;
    translating = false;
    //
    entities = new ArrayList<Entity>();

    Fisica.init(this);
    world = new FWorld();
    world.setGravity(0, 800);
    world.setEdges();

    playing = false;

    background(bg);
}

//drawing loop
public void draw() {

    if (playing){
        world.step();
        for (Entity e: entities) e.update();
        reDraw();
    }
    else {

        if (tablet.isLeftDown()&&mouseX>buttonW) penDown();
        else if (!tablet.isLeftDown() && penIsDown) penUp();
        else if ((pmouseX!=mouseX)&&(pmouseY!=mouseY))penHover();

        penSpeed = abs(mouseX-pmouseX) + abs(mouseY-pmouseY);
        tablet.saveState();

    }

}


//GUI handler
public void controlEvent (ControlEvent e){

    //UNDO
    if (e.isFrom(undoBtn)){
        if (allStrokes.size() != 0){
            undoStroke();
        }
    }

    //create Entity out of current selection 
    else if (e.isFrom(objBtn)){
        if (selectedStrokes.getSize() != 0){
            entities.add(new Entity(currentID++, selectedStrokes, world)); //create entity
            deselectStrokes();
            reDraw();
        }
    }

    else if (e.isFrom(modeRadio)){
        if ((int)e.getValue()==1){
            playing = false;
            restartGame();
            reDraw();
           // penRadio.activateAll();
        }
        else if ((int)e.getValue()==2){
            playing = true;
            reDraw();
            //penRadio.deactivateAll();
        }
    }

    //CREATE GAME OBJ

    //MODES
    else if (e.isFrom(penRadio)){
        switch ((int)e.getValue()){

            //DRAW
            case 1:
                deselectStrokes();
                reDraw();
                mode = Mode.PEN;
                break;

            //ERASE
            case 2:
                reDraw();
                //if something is selected, erase that, while remaining in select mode
                if (selectedStrokes.getMembers().size()!=0){
                    penRadio.getItem("erase").setState(false);
                    penRadio.getItem("select").setState(true);
                    eraseSelection();
                    reDraw();
                }
                //otherwise just switch to erase mode
                else mode = Mode.ERASE;
                break;

            //SELECT
            case 3:
                mode = Mode.SELECT;
                break;

            //BOXSELECT
            case 4:
                mode = Mode.BOXSELECT;
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

abstract class Component {
	//abstract void update();
}


class Entity{

  static final float RASTER_PADDING = 2f;

	StrokeGroup strokes;
  PGraphics raster;
  FPoly hull;
  int id;
  float w, h;
  PVector position;
  PVector initialPosition;

	Entity(int i, StrokeGroup sg, FWorld world){
    id = i;
    sg.belongsToEntity();
    strokes = sg;
    position = new PVector(strokes.getLeft(), strokes.getTop());
    w = strokes.getRight() - strokes.getLeft();
    h = strokes.getBottom() - strokes.getTop();
    raster = createGraphics((int)(w+RASTER_PADDING/2),(int)(h+RASTER_PADDING/2));
    setupRaster();
    setupHull();
    world.add(hull);
	}

  public void update(){
    position.x = hull.getX()+initialPosition.x;
    position.y = hull.getY()+initialPosition.y;
  }

  public void setupRaster(){
    for (Stroke s: strokes.getMembers()){
      s.draw(raster, position, RASTER_PADDING);
    }
  }

  public void setupHull(){
    GiftWrap wrapper = new GiftWrap();
    Point[] input = strokes.getKeyPoints().toArray(new Point[strokes.getKeyPointsSize()]);
    hull = wrapper.generate(input);
    hull.setPosition(0,0);
    hull.setRotatable(false);
    initialPosition = new PVector(position.x, position.y);
  }

  public void draw(){
    image(raster,position.x, position.y);
  }

  public void translate(float dx, float dy){
      position.add(dx,dy);
      //strokes.translate(dx, dy); //hull moves with stroke points!!!!!!
  }

  public FPoly getHull(){
    return hull;
  }

  public void revert(){
    hull.recreateInWorld();
    hull.setVelocity(0,0);
    hull.setPosition(0,0);
    update();
  }

}
public void restartGame(){
	for (Entity e: entities){
		e.revert();
	}
	world.step();

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

	public FPoly generate(Point[] points) {
		// check for null array
		if (points == null) throw new NullPointerException("null points");
		
		// get the size
		int size = points.length;
		Point[] hullPoints = new Point[size];
		// check the size
		if (size <= 2){
			for (int i = 0; i < size; i ++){
				hullPoints[i] = new Point(points[i].getX(), points[i].getY());
			}
		}
		
		// find the left most point
		double x = Double.MAX_VALUE;
		Point leftMost = null;
		for (int i = 0; i < size; i++) {
			Point p = points[i];
			// check for null points
			if (p == null) throw new NullPointerException("null point");
			// check the x cooridate
			if (p.getX() < x) {
				x = p.getX();
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
		
		// copy the list into FPOLY
		FPoly poly = new FPoly();
		for (Point p:hull){
			poly.vertex(p.getX(), p.getY());
		}
		
		// return the poly
		return poly;
	}

	public double getLocation(Point point, Point linePoint1, Point linePoint2) {
		return (linePoint2.getX() - linePoint1.getX()) * (point.getY() - linePoint1.getY()) -
			  (point.getX() - linePoint1.getX()) * (linePoint2.getY() - linePoint1.getY());
	}
}
class MotionComponent extends Component {
	float velocity;
	float acceleration;
	MotionComponent(){
		velocity = 0f;
		acceleration = 0f;
	}

	public void update(){
		//bloop
	}
}

// paint helper functions

//redraw everything
public void reDraw(){
    background(bg);
    if (playing) drawAllEntities();
    else drawAllStrokes();
}

//draw points corresponding to current pen location
public void draw(ArrayList<Point> points){
    stroke(currentColour);
    strokeWeight(2);
    noFill();
    beginShape();
    curveVertex(points.get(0).getX(), points.get(0).getY());
    for (int i = 0; i < points.size(); i++){
        curveVertex(points.get(i).getX(), points.get(i).getY());
    }
    if (points.size()>1) curveVertex(points.get(points.size()-1).getX(), points.get(points.size()-1).getY());
    endShape();
    // for (int i = 1; i < points.size(); i++){
    //     strokeWeight(points.get(i).weight);
    //     line(points.get(i).getX(), points.get(i).getY(), points.get(i-1).getX(), points.get(i-1).getY());;
    // }
}

//draw all strokes
public void drawAllStrokes(){
    selectedStrokes.drawBounds(color(102));
    for (Stroke selected: selectedStrokes.getMembers()){
        selected.drawSelected();
    }
    for (Stroke stroke: allStrokes){
        stroke.draw();
    }
}

public void drawAllEntities(){
    for (Entity e: entities){
        e.draw();
    }
}

//draw a box given opposite corners
public void drawBox(float x1, float y1, float x2, float y2){
    line(x1,y1,x2,y1);
    line(x2,y1,x2,y2);
    line(x2,y2,x1,y2);
    line(x1,y2,x1,y1);
}

//undo last drawn stroke
public void undoStroke(){
    allStrokes.remove(allStrokes.size()-1);
    reDraw();
}

//erase current selection
public void eraseSelection(){
    for (Stroke s: selectedStrokes.getMembers()){
        allStrokes.remove(s); //presumably slow, but it works
    }
    selectedStrokes = new StrokeGroup();
    reDraw();
}

//unselect current selection
public void deselectStrokes(){
    for (Stroke s: allStrokes){
        if (s.isSelected()) s.deselect();
    }
    selectedStrokes = new StrokeGroup();
}

//for testing
public void drawPolygon(Polygon p){
    strokeWeight(5);
    stroke(color(255,0,0));
    Vector2[] vertices = new Vector2[0];
    vertices = p.getVertices();
    for (int i = 1; i < vertices.length; i++){
        line((float)vertices[i-1].x, (float)vertices[i-1].y, (float)vertices[i].x, (float)vertices[i].y);
    }
    line((float)vertices[vertices.length-1].x, (float)vertices[vertices.length-1].y, (float)vertices[0].x, (float)vertices[0].y );
}
//PEN HANDLERS

public void penDown(){

    //ERASE: remove strokes that intersect pen
    if (mode==Mode.ERASE || (tablet.getPenKind()==Tablet.ERASER && mode==Mode.PEN)){       
        for (Stroke stroke: allStrokes){
            if (stroke.intersects(mouseX, mouseY, pmouseX, pmouseY)){
                allStrokes.remove(stroke);
                reDraw();
                break;
            }
        }
    }

    //DRAW: create strokes!
    else if (mode==Mode.PEN){

        //just pressed: instantiate new stroke
        if (!penIsDown){
            penIsDown = true;
            currentStroke = new ArrayList<Point>();
            stroke(currentColour);
        }

        if (currentStroke.add(new Point(mouseX, mouseY, 5*tablet.getPressure()))){
            reDraw();
            draw(currentStroke);
        }
        //currentStroke.draw(tablet, mouseX, mouseY, pmouseX, pmouseY);

    }

    //SELECT: select strokes that intersect pen
    //BOX SELECT: create box that will select strokes on penUp
    else if (mode==Mode.SELECT||mode==Mode.BOXSELECT){
        
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
            deselectStrokes();
            reDraw();
            if (mode==Mode.BOXSELECT){
                sx1 = mouseX;
                sy1 = mouseY;
            }
        }

        //dragging: check for strokes that intersect and select them
        else if (mode==Mode.SELECT){
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
        else if (mode==Mode.BOXSELECT){
            sx2 = mouseX;
            sy2 = mouseY;
            reDraw();
            stroke(102);
            drawBox(sx1,sy1,sx2,sy2);
        }
    }

}

public void penUp(){

    //DRAW: save finished stroke
    if (mode==Mode.PEN){
       Stroke finishedStroke = new Stroke(currentColour, currentStroke);
        allStrokes.add(finishedStroke); //add stroke
        reDraw();
    }

    //BOXSELECT: select all strokes whose **BBs** fall within created box
    //(should change this later to be more precise than BBs)
    if (mode==Mode.BOXSELECT){
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
    if (mode == Mode.SELECT || mode == Mode.BOXSELECT){
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




class Point{
    
    float weight;
    PVector coords;


    Point(float x, float y){
        coords = new PVector(x, y);
    }

    Point(float x, float y, float w){
        coords = new PVector(x, y);
        weight = w;
    }

    public void translate(float xOff, float yOff){
        coords.add(xOff, yOff, 0);
    }
    
    public float getX(){
        return coords.x;
    }
    
    public float getY(){
        return coords.y;
    }

    public Vector2 getVector2(){
        return new Vector2((double)coords.x, (double)coords.y);
    }

    public PVector getCoords(){
        return coords;
    }

    public float getWeight(){
        return weight;
    }
}



private final float TOLERANCE = 0.25f;
private final float SS_TOLERANCE = 3;
private final int MIN_POINTS_TO_SIMPLIFY = 3;
private final int META_COLOUR = color(200);
private final int META_WEIGHT = 3;
private final int MIN_AABB_SIZE = 5;

//------------------------------------------
//stroke class to contain points, color, 
//------------------------------------------
class Stroke{
    int size;
    Point[] points;
    Point[] keyPoints;
    int colour;
    float top, bottom, left, right; //bounding box coordinates
    boolean selected;
    boolean belongsToObj;
    int gameObjId;
    //fix this >>>
    private PointExtractor<Point> strokePointExtractor = new PointExtractor<Point>() {
            @Override
            public double getX(Point point) {
                return (double)point.getX();
            }

            @Override
            public double getY(Point point) {
                return (double)point.getY();
            }
        };

    Stroke(int c, ArrayList<Point> inPoints){
        //initialize variables
        size = inPoints.size();
        colour = c;
        top = Float.MAX_VALUE;
        bottom = 0;
        left = Float.MAX_VALUE;
        right = 0;
        selected = false;
        belongsToObj = false;
        gameObjId = -1;
        points = new Point[size];

        //copy the points over
        for (int i = 0; i < inPoints.size(); i++){
            this.addPoint(new Point(inPoints.get(i).getX(), inPoints.get(i).getY(), inPoints.get(i).getWeight()), i);
        }
        //set bounds accordingly
        this.setBounds();
        //simplify if there are more than the min # of points
        if (size>MIN_POINTS_TO_SIMPLIFY) this.simplify(TOLERANCE);

        keyPoints = returnSimplified(SS_TOLERANCE); //shares points with main points array!
        print(size +" vs "+ keyPoints.length + "\n");
        
    }

    //-------------------------------------
    //METHODS
    //-------------------------------------
    
    public boolean addPoint(Point p, int i){
        if (size>0){
            points[i] = p;
            return true;
        }
        return false;
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
        curveVertex(points[0].getX(), points[0].getY());
        for (int i = 0; i < size; i++){
            curveVertex(points[i].getX(), points[i].getY());
        }
        if (size>1) curveVertex(points[size-1].getX(), points[size-1].getY());
        endShape();

        // for (int i = 1; i < size; i++){
        //     strokeWeight(points[i].weight);
        //     line(points[i].getX(), points[i].getY(), points[i-1].getX(), points[i-1].getY());
        // }
        //KEYPOINTS
        // stroke(255,0,0);
        // strokeWeight(2);
        // for (int i = 1; i < keyPoints.length; i++){
        //     line(keyPoints[i].getX(), keyPoints[i].getY(), keyPoints[i-1].getX(), keyPoints[i-1].getY());;
        // }
    }

    //draw stroke onto offscreen PGraphic
    public void draw(PGraphics pg, PVector position, float padding){
        pg.beginDraw();
        pg.stroke(colour);
        pg.strokeWeight(2);
        pg.noFill();
        pg.beginShape();
        float dx = padding - position.x;
        float dy = padding - position.y;
        pg.curveVertex(points[0].getX()+dx, points[0].getY()+dy);
        for (int i = 0; i < size; i++){
            pg.curveVertex(points[i].getX()+dx, points[i].getY()+dy);
        }
        if (size>1) pg.curveVertex(points[size-1].getX()+dx, points[size-1].getY()+dy);
        pg.endShape();
        pg.endDraw();

        // pg.beginDraw();
        // pg.stroke(colour);
        // for (int i = 1; i < size; i++){
        //     pg.strokeWeight(points[i].weight);
        //     pg.line(points[i].getX()+dx, points[i].getY()+dy, points[i-1].getX()+dx, points[i-1].getY()+dy);
        // }
        // pg.endDraw();
    }

    //draw a sort of "highlight" to indicate stroke is selected
    public void drawSelected(){
        stroke(META_COLOUR);
        strokeWeight(META_WEIGHT);
        for (int i = 1; i < size; i++){
            //strokeWeight(points[i].weight+10);
            line(points[i].getX(), points[i].getY(), points[i-1].getX(), points[i-1].getY());;
        }
    }

    public void drawBounds(){
        stroke(META_COLOUR);
        strokeWeight(META_WEIGHT);
        line(left, top, right, top);
        line(right, top, right, bottom);
        line(right, bottom, left, bottom);
        line(left, bottom, left, top);
    }

    public void setBounds(){
        for (int i = 0; i < size; i++){
            if (points[i].getX() < left) left = points[i].getX();
            if (points[i].getX() > right) right = points[i].getX();
            if (points[i].getY() < top) top = points[i].getY();
            if (points[i].getY() > bottom) bottom = points[i].getY();
        }
        //bloat small points?
        bloatSmallBounds(MIN_AABB_SIZE);
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
            for (int i=1; i<size; i++){
                if (Line2D.linesIntersect(x1,y1,x2,y2,points[i].getX(),
                    points[i].getY(), points[i-1].getX(), points[i-1].getY())){
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
    //     for (int i=1; i<size; i++){
    //         if (rectIntersectsLine(x-speed/2, y-speed/2, x+speed/2, y+speed/2,points[i].getX(),
    //                 points[i].getY(), points[i-1].getX(), points[i-1].getY())){
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

//testing simplify library
    public void simplify(float tolerance){
        points = returnSimplified(tolerance);
        size = points.length;
    }

    public Point[] returnSimplified(float tolerance){
        Simplify<Point> simplify = new Simplify<Point>(new Point[0], strokePointExtractor);
        return simplify.simplify(points, tolerance, true);
    }


// --------------------------------------
// GETTERS AND SETTERS
// --------------------------------------

    public int getSize(){
        return size;
    }

 public Point[] getPoints() {
        return points;
    }

    public void setPoints(Point[] points) {
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

    public void addToGameObj(int id){
        gameObjId = id;
        belongsToObj = true;
    }
}



class StrokeGroup{

	ArrayList<Stroke> members;
	ArrayList<Point> allKeyPoints;
	//ArrayList<Vector2[]> allKeyPoints;
	//List<Polygon> polygons;
	float top, bottom, left, right; //group bounding box
	boolean selected;
	boolean belongsToEntity;
	int keyPointsSize, size;

	StrokeGroup(){
		members = new ArrayList<Stroke>();
		allKeyPoints = new ArrayList<Point>();
		//allKeyPoints = new ArrayList<Vector2>();
		//polygons = new ArrayList<Polygon>();

		selected = true;
		belongsToEntity = false;
		top = Float.MAX_VALUE;
        bottom = 0;
        left = Float.MAX_VALUE;
        right = 0;
        keyPointsSize = 0;
        size = 0;

	}

	public void addMember(Stroke s){
		members.add(s);
		size++;
		keyPointsSize += s.keyPoints.length;
		Collections.addAll(allKeyPoints, s.keyPoints);
		if (s.left < left) left = s.left;
        if (s.right > right) right = s.right;
        if (s.top < top) top = s.top;
        if (s.bottom > bottom) bottom = s.bottom;
	}

	public boolean boundsContain(float x, float y){
        if (x > left && x < right && y > top && y < bottom) return true;
        else return false;
    }

    public void draw(){
    	for (Stroke s: members){
    		s.draw();
    	}
    	if (belongsToEntity) drawBounds(color(50,50,255));
    }

    public void drawBounds(int c){
        stroke(c);
        strokeWeight(2);
        drawBox(left, top, right, bottom);
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

	 public StrokeGroup copy(){
	 	StrokeGroup copy = new StrokeGroup();
	 	for (Stroke s: members){
	 		copy.members.add(s);
	 	}
	 	for (Point p: allKeyPoints){
	 		copy.allKeyPoints.add(p);
	 	}
	 	copy.selected = selected;
		copy.top = top;
        copy.bottom = bottom;
        copy.left = left;
        copy.right = right;
        copy.keyPointsSize = keyPointsSize;
        copy.size = size;

        return copy;
	 }

    // void decompose(){
    // 	Vector2[] inputPoints = new Vector2[0];
    // 	inputPoints = allKeyPoints.toArray(inputPoints);
    // 	Bayazit decomposer = new Bayazit();
    // 	List<Convex> convexShapes = new ArrayList<Convex>();
    // 	convexShapes = decomposer.decompose(inputPoints);
    // 	for (Convex shape: convexShapes){
    // 		polygons.add((Polygon)shape);
    // 	}
    // }

// --------------------------------------
// GETTERS AND SETTERS
// --------------------------------------

	public ArrayList<Point> getKeyPoints(){
		return allKeyPoints;
	}

	public ArrayList<Stroke> getMembers() {
		return members;
	}

	public int getSize(){
		return size;
	}

	public int getKeyPointsSize(){
		return keyPointsSize;
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

	public void belongsToEntity(){
		belongsToEntity = true;
	}

	public void removeFromEntity(){
		belongsToEntity = false;
	}

}
    public void settings() {  fullScreen(2); }
    static public void main(String[] passedArgs) {
        String[] appletArgs = new String[] { "paint" };
        if (passedArgs != null) {
          PApplet.main(concat(appletArgs, passedArgs));
        } else {
          PApplet.main(appletArgs);
        }
    }
}
