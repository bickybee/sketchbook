import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import com.goebl.simplify.*; 
import codeanticode.tablet.*; 
import controlP5.*; 
import java.awt.geom.*; 
import fisica.*; 
import java.lang.reflect.*; 
import fisica.*; 
import java.util.List; 
import java.lang.reflect.*; 
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
StrokeGroup canvasStrokes;
int currentColour;
int bg;
StrokeGroup selectedStrokes;

//penStuff
Mode mode;
boolean translating;
boolean penIsDown;
float penSpeed;
//offsets for translation
float xOffset;
float yOffset;
//points for building selection-square
float sx1, sy1, sx2, sy2;

//GUI stuff 
ControlP5 gui;
int buttonW = 60;
int buttonH = 40;
Button undoBtn;
Button objBtn;
Button playBtn;
RadioButton penRadio;
RadioButton colourRadio;
RadioButton modeRadio;
Toggle gravityTog;
boolean playing; //play mode vs. paint mode

//GAME STUFF!!!!!!!
ArrayList<GameObj> gameObjs;
int currentID;
GameObj selectedGameObj;
FWorld world;
KeyPublisher[] keys;
PGraphics background;

public void setup() {
     

    //INITIALIZING EVERTHING
    tablet = new Tablet(this);
    bg = color(255);
    currentColour = color(0,0,0);
    currentStroke = new ArrayList<Point>();
    canvasStrokes = new StrokeGroup();
    selectedStrokes = new StrokeGroup();
    //
    penIsDown = false;
    mode = Mode.PEN;
    translating = false;
    //
    keys = new KeyPublisher[200]; //corresponds to each key, ascii up to 127 and with an offset of 127 for coded keys
    for (int i = 0; i < keys.length; i++){
        keys[i] = new KeyPublisher(i);
    }
    gameObjs = new ArrayList<GameObj>();
    Fisica.init(this);
    world = new FWorld();
    world.setGravity(0, 0);
    world.setEdges();

    playing = false;
    currentID = 0;

    //controlP5 initializations
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

    gravityTog = gui.addToggle("gravity")
        .setLabel("gravity")
        .setColorLabel(color(0))
        .setPosition(0,buttonH*12+40)
        .setSize(buttonW, buttonH);

    background(bg);
}

//drawing loop
public void draw() {

    //if in play mode, step through world every frame
    //update game objects accordingly
    //redraw
    if (playing){
        world.step();
        for (GameObj obj: gameObjs) obj.update();
        reDraw();
    }
    //if in paint mode,
    //use appropriate pen handler depending on pen mode
    else {

        if (tablet.isLeftDown()&&mouseX>buttonW) penDown();
        else if (!tablet.isLeftDown() && penIsDown) penUp();
        else if ((pmouseX!=mouseX)&&(pmouseY!=mouseY))penHover();

        penSpeed = abs(mouseX-pmouseX) + abs(mouseY-pmouseY);
        tablet.saveState();

    }

}

//undo stroke button handler
public void undo(int val){
    if (canvasStrokes.getSize() != 0){
            undoStroke();
    }
}

//create game object button handler
public void gameObj(int val){
    if (selectedStrokes.getSize() != 0){
        GameObj newObj = new GameObj(currentID, selectedStrokes, world, gui); //create entity
        gameObjs.add(newObj);
        keys['a'].addSubscriber(newObj, "testMethod");
        currentID++;
        for (Stroke s : selectedStrokes.getMembers()){
            canvasStrokes.removeMember(s);
        }
        deselectStrokes();
        reDraw();
    } 
}

//play vs. draw mode, radio handler
public void mode(int val){
    switch(val){
        //paint mode
        case(1):
            playing = false;
            //remove game objects from game world
            //show their editing menus
            for (GameObj obj: gameObjs){
                obj.showUI();
                world.remove(obj.getBody());
                world.step();
            }
            restartGame();
            reDraw();
           break;
        //play mode
        case(2):
            playing = true;
            //add game objects to game world
            //hide their editing menus
            for (GameObj obj: gameObjs){
                obj.hideUI();
                world.add(obj.getBody());
                world.step();
            }

            reDraw();
            break;
        default:
    }
}

//pen-mode radio handler
public void pens(int val){
    switch (val){

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

//pen colour radio handler
public void colour(int val){
    
    currentColour = val;
    stroke(currentColour);

    //if some strokes are selected, set them to the selected colour
    if (selectedStrokes.getMembers().size()!=0){
        for (Stroke s: selectedStrokes.getMembers()){
            s.setColour(currentColour);
        }
        reDraw();
    }
}

public void gravity(int val){
    if (world!= null){
        if (gravityTog.getBooleanValue()) world.setGravity(0,800);
        else world.setGravity(0,0);
    }
    
}

//game object editing menu handler
public void controlEvent(ControlEvent event){
    //check if any game object's interfaces cased the event
    for (GameObj obj: gameObjs){

        //if it's from the attribute menu, update accordingly
        if (event.isFrom(obj.getUI())){
            obj.updateAttributes();

            //TESTING KEY BINDINGS FOR CONTROL
            if (obj.getUI().getState(6)){
                keys[127+UP].addSubscriber(obj, "moveUp");
                keys[127+DOWN].addSubscriber(obj, "moveDown");
                keys[127+LEFT].addSubscriber(obj, "moveLeft");
                keys[127+RIGHT].addSubscriber(obj, "moveRight");
                obj.getBody().setDensity(500); // "kinematic" body lol
            }
            else {
                keys[127+UP].removeSubscriber(obj);
                keys[127+DOWN].removeSubscriber(obj);
                keys[127+LEFT].removeSubscriber(obj);
                keys[127+RIGHT].removeSubscriber(obj);                
            }
            
        }

        //if it's from the select button, select/deselect objects accordingly
        //(since only one obj may be selected at a time)
        else if (event.isFrom(obj.getSelectBtn())){

            if (selectedGameObj==obj){
                selectedGameObj.deselect();
                reDraw();
                selectedGameObj = null;
            }
            else {
                if (selectedGameObj!=null) selectedGameObj.deselect();
                selectedGameObj = obj;
                obj.select();
                reDraw();
            }
            print("selected \n");
        }
    }
}
public void setKeyState(boolean isPushed){
    if (key==CODED){
        try {
            keys[keyCode+127].set(isPushed);
        } catch (IndexOutOfBoundsException e) {
            print("Key not supported \n");
        }
    }
    else {
        keys[key].set(isPushed);
    }
}
public void keyPressed(){
    setKeyState(true);
}

public void keyReleased(){
    setKeyState(false);
}
//encompasses all possible game object behaviours
abstract public class Behaviour{

	GameObj parent;
	boolean activated;

	Behaviour(GameObj obj){
		parent = obj;
	}

	abstract public void update(boolean state);

	public void activate(){
		activated = true;
	}

	public void deactivate(){
		activated = false;
	}

}
//encompasses all possible events, that may instigate game object bheaviours
abstract public class Event{

	ArrayList<Behaviour> subscribers;
	boolean occuring;

	Event(){
		subscribers = new ArrayList<Behaviour>();
	}

	public void addSubscriber(Behaviour b){
		if (!subscribers.contains(b)){
			subscribers.add(b);
		}
	}

	public void removeSubscriber(Behaviour b){
		subscribers.remove(b);
	}

	public void notifySubscribers(){
		for (Behaviour b: subscribers){
			b.update(occuring);
		}
	}

}
public void restartGame(){
	for (GameObj obj: gameObjs){
		obj.revert();
	}
	world.step();

}


//Game Object
//Keeps stroke and game data
class GameObj{

  //padding required to account for stroke width
  static final float RASTER_PADDING = 2f;

	private StrokeGroup strokeGroup; 
  private PGraphics raster;
  private FBody body; 
  private ArrayList<FBody> bodies; //if there are duplicate bodies
  private int id;
  private float w, h;
  private PVector position; //position in editing mode
  private PVector rasterPosition;
  private CheckBox ui; //attribute editor ui
  private Button selectBtn; //used to select object for editing
  private Method[] keyListeners;

  //some attribute bools
  private  boolean pickup, visible, slippery, bouncy, isInWorld, selected;

	GameObj(int i, StrokeGroup sg, FWorld world, ControlP5 cp5){
    id = i;
    strokeGroup = sg;

    //label strokes as belonging to this game object
    for (Stroke s: strokeGroup.getMembers()) s.addToGameObj(id, this);
    keyListeners = new Method[200];
    w = strokeGroup.getRight() - strokeGroup.getLeft();
    h = strokeGroup.getBottom() - strokeGroup.getTop();
    raster = createGraphics((int)(w+RASTER_PADDING),(int)(h+RASTER_PADDING));
    body = setupBody(false);
    bodies = new ArrayList<FBody>();
    position = new PVector(strokeGroup.getLeft(), strokeGroup.getTop());
    rasterPosition = new PVector(position.x, position.y);

    pickup = false;
    visible = true;
    slippery = false;
    bouncy = false;
    isInWorld = true;
    selected = false;
    setupRaster();
    setupMenu(Integer.toString(id), cp5);

	}

///////////////////////////////////////////////
// drawing
//////////////////////////////////////////////

  //for each world.step, move raster position to game position
  public void update(){
    rasterPosition.x = body.getX()+position.x;
    rasterPosition.y = body.getY()+position.y;
    if (pickup){
      if (body.getContacts().size()!=0){//for now, pickups disappear upon contact with any body
        world.remove(body);
        isInWorld = false;
      }
    }
  }

  //draw the sprite where the body is
  public void draw(){
    if (visible&&isInWorld) image(raster,rasterPosition.x, rasterPosition.y);
  }

  public void draw(FBody b){
    if (visible&&isInWorld){
      image(raster, b.getX()+position.x, b.getY()+position.y);
    }
  }

  //draw vector strokeGroup onto raster sprite
  private void setupRaster(){
    strokeGroup.createRaster(raster, rasterPosition, RASTER_PADDING/2);
  }

///////////////////////////////////////////////
// stroke editing
//////////////////////////////////////////////

  public void removeStroke(Stroke s){
    s.removeFromGameObj();
    strokeGroup.removeMember(s);
    if (strokeGroup.getSize()>0) recalculateStrokeDependentData();
  }

  public void addStroke(Stroke s){
    s.addToGameObj(id, this);
    strokeGroup.addMember(s);
    recalculateStrokeDependentData();
  }

  public void updateStrokes(){
    strokeGroup.update();
    recalculateStrokeDependentData();
  }

  //when messing with the strokes in the strokegroup, we need to update geometry accordingly
  private void recalculateStrokeDependentData(){
    position = new PVector(strokeGroup.getLeft(), strokeGroup.getTop());
    w = strokeGroup.getRight() - strokeGroup.getLeft();
    h = strokeGroup.getBottom() - strokeGroup.getTop();
    raster = createGraphics((int)(w+RASTER_PADDING),(int)(h+RASTER_PADDING));
    newBody(ui.getState(2)); //should probably use a bool
    setupRaster();
    ui.getParent().setPosition(position.x+77, position.y+h+20);
    selectBtn.setPosition(position.x, position.y+h);
  }

///////////////////////////////////////////////
// physics body creation/updating
//////////////////////////////////////////////

  //setup physics body for gameobj
  //if isExact, use the precise points to create the body as a series of lines
  //otherwise create a wrapping polygon
  private FBody setupBody(boolean isExact){
    FBody b;
    if (isExact) b = createLineCompound(false);
    else b = createHull();
    b.setPosition(0,0);
    b.setRotatable(false);
    b.setRestitution(0);
    b.setFriction(10);
    b.setDamping(0);
    return b;
  }

//use giftwrap algorithm to create convex body FPoly
  private FPoly createHull(){
    GiftWrap wrapper = new GiftWrap();
    ArrayList<Point> allKeyPoints = new ArrayList<Point>();
    for (Stroke s : strokeGroup.getMembers()){
      Collections.addAll(allKeyPoints, s.keyPoints);
    }
    Point[] input = allKeyPoints.toArray(new Point[allKeyPoints.size()]);
    return wrapper.generate(input);
  }

  //string together key points to make a big line body
  private FCompound createLineCompound(boolean isJumpThrough){
      FCompound lines = new FCompound();
      for (Stroke s: strokeGroup.getMembers()){
        for (int i = 1; i < s.keyPoints.length; i++){
          lines.addBody(new FLine(s.keyPoints[i-1].getX(), s.keyPoints[i-1].getY(),s.keyPoints[i].getX(), s.keyPoints[i].getY()));
          //need DOUBLE-SIDED LINE... creating another line in the opposite direction with a slight offset works for simple lines
          //lines.addBody(new FLine(s.keyPoints[s.keyPoints.length-i].getX(), s.keyPoints[s.keyPoints.length-i].getY()+5,
           //                       s.keyPoints[s.keyPoints.length-i-1].getX(), s.keyPoints[s.keyPoints.length-i-1].getY()+5));
          //how about other shapes? circles with interiors? :/
        }
      }
      return lines;
  }

  private void newBody(boolean isExact){
      world.remove(body);
      FBody newBody = setupBody(isExact);
      newBody.setStatic(body.isStatic());
      newBody.setSensor(body.isSensor());
      body = newBody;
      setSlippery(slippery);
      setBouncy(bouncy);
  }


///////////////////////////////////////////////
// setting attributes & behaviours
//////////////////////////////////////////////

  public void setStatic(boolean state){
    if (state!=body.isStatic()) body.setStatic(state);
  }

  public void setSolid(boolean state){
    if (state!=body.isSensor()) body.setSensor(state);
  }

  public void setExact(boolean state){
    if ((state&&(body instanceof FPoly))||(!state)&&(body instanceof FCompound)){ 
      newBody(state);
    }
  }

  public void setPickup(boolean state){
    pickup = state;
  }

  public void setBouncy(boolean state){
    bouncy = state;
    if (bouncy) body.setRestitution(1);
    else body.setRestitution(0);
  }

  public void setSlippery(boolean state){
    slippery = state;
    if (slippery) body.setFriction(0);
    else body.setFriction(10);
  }

///////////////////////////////////////////////
// behaviours
//////////////////////////////////////////////

  public void moveUp(boolean move){
    if (move) body.setVelocity(body.getVelocityX(),-500);
    else body.setVelocity(body.getVelocityX(), 0);
  }

  public void moveDown(boolean move){
    if (move) body.setVelocity(body.getVelocityX(),500);
    else body.setVelocity(body.getVelocityX(), 0);
  }

  public void moveRight(boolean move){
    if (move) body.setVelocity(500,body.getVelocityY());
    else body.setVelocity(0, body.getVelocityY());
  }

  public void moveLeft(boolean move){
    if (move) body.setVelocity(-500,body.getVelocityY());
    else body.setVelocity(0, body.getVelocityY());
  }

  public void testMethod(boolean keyPushed){
    if (keyPushed) print("method invoked true \n");
    else print("method invoked false \n");
  }


///////////////////////////////////////////////
// menu setup/listeners
//////////////////////////////////////////////

    //setup attributes menu
  private void setupMenu(String id, ControlP5 cp5){
    Group menu = cp5.addGroup("attributes_"+id).setBackgroundColor(color(0, 64))
    .setPosition(position.x+77, position.y+h+20)
    .setHeight(20)
    .setWidth(75)
    .close();

    ui = cp5.addCheckBox("checkbox"+id)
   .setPosition(0,0)
   .setItemWidth(20)
   .setItemHeight(20)
   .addItem("static_"+id, 1)
   .addItem("sensor_"+id, 2)
   .addItem("exact_"+id, 3)
   .addItem("pickup_"+id, 4)
   .addItem("bouncy_"+id, 5)
   .addItem("slippery_"+id, 6)
   .addItem("controllable_"+id, 7)
   .setColorLabel(color(0))
   .moveTo(menu);

   selectBtn = cp5.addButton("edit_strokes_"+id)
      .setPosition(position.x,position.y+h)
      .setHeight(20)
      .setWidth(75);
  }

  public void updateAttributes(){
    setStatic(ui.getState(0));
    setSolid(ui.getState(1));
    setExact(ui.getState(2));
    setPickup(ui.getState(3));
    setBouncy(ui.getState(4));
    setSlippery(ui.getState(5));
  }

  //for switching between paint and play mode-- restart play
  public void revert(){
    body.recreateInWorld();
    body.setVelocity(0,0);
    body.setPosition(0,0);
    update();
  }

///////////////////////////////////////////////
// key listening
//////////////////////////////////////////////

  public void bindMethodToKey(Method method, int keyVal){
    keyListeners[keyVal] = method;
  }

  public void removeKeyBinding(int keyVal){
    keyListeners[keyVal] = null;
  }

  //receive notifications from keys
  public void notify(boolean isPushed, int keyVal){
    if (keyListeners[keyVal]!=null){
      try {
        keyListeners[keyVal].invoke(this, isPushed);
      } catch (Exception e){
        print(e+" from GameObj notify \n");
      }
    }
  }

///////////////////////////////////////////////
// getters and setters
//////////////////////////////////////////////

  public FBody getBody(){
    return body;
  }


  public StrokeGroup getStrokes(){
    return strokeGroup;
  }

  public CheckBox getUI(){
    return ui;
  }

  public Button getSelectBtn(){
    return selectBtn;
  }

  public void hideUI(){
    ui.getParent().hide();
    selectBtn.hide();
  }

  public void showUI(){
    ui.getParent().show();
    selectBtn.show();
  }

  public void select(){
    selected = true;
  }

  public void deselect(){
    selected = false;
  }

  public boolean isSelected(){
    return selected;
  }

  public int getID(){
    return id;
  }

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
//key listener/publisher (where GameObjs are the subscribers)


public class KeyPublisher{

	ArrayList<GameObj> subscribers;
	boolean isPushed;
	int keyValue;

	KeyPublisher(int val){
		keyValue = val;
		isPushed = false;
		subscribers = new ArrayList<GameObj>();

	}

	public void set(boolean pushed){
		if (isPushed != pushed){
			isPushed = pushed;
			notifySubscribers();	
		}	
	}

	public void addSubscriber(GameObj obj, String methodName){
		if (!subscribers.contains(obj)){
			try {
				Method method = obj.getClass().getMethod(methodName, boolean.class);
				print(keyValue);
				obj.bindMethodToKey(method, keyValue);
				subscribers.add(obj);
				print("subscribed to "+keyValue+"\n");
			} catch (Exception e) {
				print(e+" from addSubsriber \n");
			}
		}
	}

	public void removeSubscriber(GameObj obj){
		subscribers.remove(obj);
		obj.removeKeyBinding(keyValue);
	}

	private void notifySubscribers(){
		for (GameObj obj : subscribers){
			obj.notify(isPushed, keyValue);
		}
	}

}

// paint helper functions

//redraw everything
public void reDraw(){
    background(bg);
    if (playing) drawAllGameObjs();
    else{
        for (GameObj obj: gameObjs){
            if (!obj.isSelected()) obj.getStrokes().drawBounds(color(135,206,250));
            else obj.getStrokes().drawBounds(color(50,206,135));
        }
    	drawAllStrokes();
    }
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
    for (Stroke selected: selectedStrokes.getMembers()){
        selected.drawSelected();
    }
    for (Stroke stroke: canvasStrokes.getMembers()){
        stroke.draw();
    }
    for (GameObj obj : gameObjs){
        obj.getStrokes().draw();
    }
}

public void drawAllGameObjs(){
    for (GameObj obj: gameObjs){
        obj.draw();
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
    //FIX THIS GROSS LINE
    canvasStrokes.removeMember(canvasStrokes.getMembers().get(canvasStrokes.getSize()-1));
    reDraw();
}

//erase current selection
public void eraseSelection(){
    for (Stroke s: selectedStrokes.getMembers()){
        canvasStrokes.removeMember(s); //presumably slow, but it works
    }
    selectedStrokes = new StrokeGroup();
    reDraw();
}

//unselect current selection
public void deselectStrokes(){
    for (Stroke s: canvasStrokes.getMembers()){
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
    if (mode==Mode.ERASE || (tablet.getPenKind()==Tablet.ERASER)){    
        if (selectedGameObj==null) eraseFrom(canvasStrokes);
        else eraseFrom(selectedGameObj);   
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
        if (tablet.getPenKind()==Tablet.ERASER){
            eraseSelection();
            reDraw();
        }

        //translate: move selection along with pen
        else if (translating){
            penIsDown = true;
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
            if (selectedGameObj==null) selectStrokesFrom(canvasStrokes);
            else selectStrokesFrom(selectedGameObj.getStrokes());
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
    if (translating&&(selectedGameObj!=null)){
        selectedGameObj.updateStrokes();
        reDraw();
    }

    //DRAW: save finished stroke
    if (mode==Mode.PEN){
       Stroke finishedStroke = new Stroke(currentColour, currentStroke);
        if (selectedGameObj==null) canvasStrokes.addMember(finishedStroke); //add stroke
        else selectedGameObj.addStroke(finishedStroke);
        reDraw();
    }

    //BOXSELECT: select all strokes whose **BBs** fall within created box
    //(should change this later to be more precise than BBs)
    else if (mode==Mode.BOXSELECT){
        if (selectedGameObj==null) boxSelectFrom(canvasStrokes);
        else boxSelectFrom(selectedGameObj.getStrokes());
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

public void eraseFrom(StrokeGroup strokes){
    for (Stroke stroke: strokes.getMembers()){
        //if erasing line intersects stroke, remove it from list of strokes
        if (stroke.intersects(mouseX, mouseY, pmouseX, pmouseY)){
            //if this stroke is part of the current stroke selection, erase the whole selection
            if (selectedStrokes.getMembers().contains(stroke)) eraseSelection();
            //otherwise just erase that stroke
            else strokes.removeMember(stroke);
            reDraw();
            break;
        }
    }
}

public void eraseFrom(GameObj obj){
    eraseFrom(obj.getStrokes());
    if (obj.getStrokes().getSize()==0){ //if there are no more strokes left in the obj, remove it
        obj.hideUI();
        gameObjs.remove(obj);
        selectedGameObj = null;
    }  
}

public void selectStrokesFrom(StrokeGroup strokes){
    for (Stroke stroke: strokes.getMembers()){
        if (!stroke.isSelected()&&stroke.intersects(mouseX, mouseY, pmouseX,pmouseY)){
            stroke.select();
            selectedStrokes.addMember(stroke);
            print("selected strokes: "+selectedStrokes.getSize()+"\n");
            reDraw();
            break;
        }
    }
}

public void boxSelectFrom(StrokeGroup strokes){
    for (Stroke s: strokes.getMembers()){
        if (!s.isSelected()&&s.boundsIntersectRect(min(sx1,sx2), min(sy1,sy2), max(sx1,sx2), max(sy1,sy2))){
            s.select();
            selectedStrokes.addMember(s);
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
public class SimpleMovement extends Behaviour{

	PVector velocity;
	FBody parentBody;

	SimpleMovement(GameObj o, PVector v){
		super(o);
		velocity = v;
		parentBody = parent.getBody();
	}

	public void update(boolean state){
		if (state) parentBody.setVelocity(velocity.x, velocity.y);
		else parentBody.setVelocity(0, 0);
	}

}



private final float TOLERANCE = 0.25f;
private final float SS_TOLERANCE = 3;
private final int MIN_POINTS_TO_SIMPLIFY = 3;
private final int META_COLOUR = color(200);
private final int META_WEIGHT = 10;
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
    GameObj gameObj;
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

    public void addToGameObj(int id, GameObj o){
        selected = false;
        gameObj = o;
        gameObjId = id;
        belongsToObj = true;
    }

    public void removeFromGameObj(){
        belongsToObj = false;
    }

    public boolean belongsToGameObj(){
        return belongsToObj;
    }

    public int getGameObjID(){
        if (belongsToObj) return gameObjId;
        else return -1;
    }

    public GameObj getGameObj(){
        return gameObj;
    }
}



class StrokeGroup{

	ArrayList<Stroke> members;
	float top, bottom, left, right;
	boolean selected;
	boolean belongsToEntity;
	int size;

	StrokeGroup(){
		members = new ArrayList<Stroke>();
		selected = true;
		belongsToEntity = false;
		top = Float.MAX_VALUE;
        bottom = 0;
        left = Float.MAX_VALUE;
        right = 0;
        size = 0;

	}

	public void addMember(Stroke s){
		members.add(s);
		size++;
		if (s.left < left) left = s.left;
        if (s.right > right) right = s.right;
        if (s.top < top) top = s.top;
        if (s.bottom > bottom) bottom = s.bottom;
	}

	public void removeMember(Stroke stroke){
		members.remove(stroke);
		size--;
		//recalculate bounding box
		update();
	}

	//recalculate key points & bounding box
	public void update(){
		top = Float.MAX_VALUE;
        bottom = 0;
        left = Float.MAX_VALUE;
        right = 0;
		for (Stroke s: members){
			if (s.left < left) left = s.left;
	        if (s.right > right) right = s.right;
	        if (s.top < top) top = s.top;
	        if (s.bottom > bottom) bottom = s.bottom;
		}
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
        strokeWeight(10);
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
	 	copy.selected = selected;
		copy.top = top;
        copy.bottom = bottom;
        copy.left = left;
        copy.right = right;
        copy.size = size;

        return copy;
	 }

	 public void createRaster(PGraphics raster, PVector pos, float padding){
	 	for (Stroke s: members){
      		s.draw(raster, pos, padding/2);
    	}
	 }


// --------------------------------------
// GETTERS AND SETTERS
// --------------------------------------

	public ArrayList<Stroke> getMembers() {
		return members;
	}

	public int getSize(){
		return size;
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
