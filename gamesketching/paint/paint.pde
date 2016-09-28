import com.goebl.simplify.*;
import codeanticode.tablet.*;
import controlP5.*;
import java.awt.geom.*;
import fisica.*;
import java.lang.reflect.*;
import java.util.Random.*;


//canvas stuff
Tablet tablet;
ArrayList<Point> currentStroke;
StrokeGroup canvasStrokes;
color currentColour;
color bg;
StrokeGroup selectedStrokes;
float scaleValue;
float panX;
float panY;
PGraphics newFrame;

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
Button clearBtn;
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
PGraphics background;
FContact currentContact;
KeyEvent[] keyEvents;
ArrayList<CollisionEvent> collisionEvents;
ArrayList<FrequencyEvent> frequencyEvents;
Random random;

void setup() {
    fullScreen(2);
    //INITIALIZING EVERTHING
    tablet = new Tablet(this);
    bg = color(255);
    currentColour = color(0,0,0);
    currentStroke = new ArrayList<Point>();
    canvasStrokes = new StrokeGroup();
    selectedStrokes = new StrokeGroup();
    scaleValue = 1;
    //
    penIsDown = false;
    mode = Mode.PEN;
    translating = false;
    //
    keyEvents = new KeyEvent[200]; //corresponds to each key, ascii up to 127 and with an offset of 127 for coded keys
    for (int i = 0; i < keyEvents.length; i++){
        keyEvents[i] = new KeyEvent(i);
    }
    gameObjs = new ArrayList<GameObj>();
    collisionEvents = new ArrayList<CollisionEvent>();
    frequencyEvents = new ArrayList<FrequencyEvent>();
    random = new Random();
    Fisica.init(this);
    world = new FWorld();
    //currentContact = new FContact();
    world.setGravity(0, 0);
    world.setEdges(buttonW+5,0,width,height);
    world.left.setName("left");
    world.right.setName("right");
    world.top.setName("top");
    world.bottom.setName("bottom");

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
    
    //clearBtn = gui.addButton("clear")
    //          .setPosition(0,buttonH*12+40)
    //          .setSize(buttonW, buttonH)
    //          .activateBy(ControlP5.PRESSED);
            

    background(bg);
}

//drawing loop
void draw() {

    //if in play mode, step through world every frame
    //update game objects accordingly
    //handle frequency events here
    //redraw
    if (playing){
        world.step();
        for (GameObj obj: gameObjs) obj.update();
        for (FrequencyEvent f : frequencyEvents){
            if (f.getFrequency()==0){
                f.set(true, true);
            }
            else if ((round(millis()/(f.getFrequency()*100))%10)==0){
                f.set(true);
            }
            else{
                f.set(false);
            }
        }
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
        currentID++;
        for (Stroke s : selectedStrokes.getMembers()){
            canvasStrokes.removeMember(s);
        }
        deselectStrokes();
        reDraw();
    } 
}

////undo stroke button handler
//public void clear(int val){
//    gameObjs.clear();
//    collisionEvents.clear();
//    frequencyEvents.clear();
//    playing = false;
//    currentID = 0;
//    canvasStrokes = new StrokeGroup();
//    selectedStrokes = new StrokeGroup();
//    reDraw();
//}

//play vs. draw mode, radio handler
public void mode(int val){
    switch(val){
        //paint mode
        case(1):
            playing = false;
            //stopGame();
            //remove game objects from game world
            //show their editing menus
            for (GameObj obj: gameObjs){
                obj.showUI();
                for (FBody b : obj.getBodies()){
                    world.remove(b);
                }
                obj.clearBodies();
            }
            world.step();
            reDraw();
           break;
        //play mode
        case(2):
            playing = true;
            //startGame();
            //add game objects to game world
            //hide their editing menus
            for (GameObj obj: gameObjs){
                obj.hideUI();
                world.add(obj.spawnBody());
            }
            world.step();
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

//game object editing menu handler
public void controlEvent(ControlEvent event){
    //check if any game object's interfaces cased the event
    for (GameObj obj: gameObjs){

        //if it's from the attribute menu, update accordingly
        if (event.isFrom(obj.getUI())){
            obj.updateAttributes();

            //TESTING KEY BINDINGS FOR CONTROL
            if (obj.getUI().getState(6)){
                keyEvents[127+UP].add(new Velocity(obj, new PVector(0,-500)));
                keyEvents[127+DOWN].add(new Velocity(obj, new PVector(0,500)));
                keyEvents[127+LEFT].add(new Velocity(obj, new PVector(-500,0)));
                keyEvents[127+RIGHT].add(new Velocity(obj, new PVector(500,0)));
            }
            else {
                keyEvents[127+UP].remove(obj);
                keyEvents[127+DOWN].remove(obj);
                keyEvents[127+LEFT].remove(obj);
                keyEvents[127+RIGHT].remove(obj);                 
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
            keyEvents[keyCode+127].set(isPushed);
        } catch (IndexOutOfBoundsException e) {
            print("Key not supported \n");
        }
    }
    else {
        keyEvents[key].set(isPushed);
    }
}
public void keyPressed(){
    //ZOOM?
    // if (key=='2'){
    //     if (scaleValue>1) scaleValue+=1;
    //     else scaleValue*=2;
    //     reDraw();
    // }
    // else if (key=='1'){
    //     if (scaleValue>1) scaleValue-=1;
    //     else scaleValue/=2;
    //     reDraw();
    // }
    //testing out some combinations of EVENTS and BEHAVIOURS
    if ((!playing)&&(selectedGameObj!=null)){
        switch (key){
            //destroy on collision
            case 'x':
                print("new collision \n");
                CollisionEvent c = new CollisionEvent(Integer.toString(selectedGameObj.getID()));
                c.add(new Destroy(selectedGameObj, world, false));
                collisionEvents.add(c);
                break;

            //animate on up key (with newFrame raster)
            case 'a':
                print("new animate \n");
                keyEvents[UP+127].add(new Animate(selectedGameObj, newFrame, 0));
                break;

            //for the ball in pong
            case 'b':
                print("ball behaviour \n");
                FrequencyEvent f = new FrequencyEvent(0);
                f.add(new Speed(selectedGameObj, 500, new PVector(1,0)));
                frequencyEvents.add(f);
                CollisionEvent left = new CollisionEvent(Integer.toString(selectedGameObj.getID()), "left");
                CollisionEvent right = new CollisionEvent(Integer.toString(selectedGameObj.getID()), "right");
                Destroy d = new Destroy(selectedGameObj, world, true);
                Spawn s = new Spawn(selectedGameObj, world);
                left.add(d);
                left.add(s);
                right.add(d);
                right.add(s);
                collisionEvents.add(left);
                collisionEvents.add(right);
                break;

            //for the paddle in pong
            case 'r':
                print("right paddle behaviour \n");
                keyEvents[UP+127].add(new Velocity(selectedGameObj, new PVector(0,-500)));
                keyEvents[DOWN+127].add(new Velocity(selectedGameObj, new PVector(0,500)));
                break;

            case 'l':
                print("left paddle behaviour \n");
                keyEvents['w'].add(new Velocity(selectedGameObj, new PVector(0,-500)));
                keyEvents['s'].add(new Velocity(selectedGameObj, new PVector(0,500)));
                break;

            //spawn at consistent frequency
            case 's':
                print("spawning behaviour");
                FrequencyEvent spawn = new FrequencyEvent(1.5);
                CollisionEvent left2 = new CollisionEvent(Integer.toString(selectedGameObj.getID()), "left");
                CollisionEvent right2 = new CollisionEvent(Integer.toString(selectedGameObj.getID()), "right");
                Destroy d2 = new Destroy(selectedGameObj, world, false);
                spawn.add(new Spawn(selectedGameObj, world));
                left2.add(d2);
                right2.add(d2);
                collisionEvents.add(left2);
                collisionEvents.add(right2);
                frequencyEvents.add(spawn);
                break;

            case '2':
                print("move right");
                FrequencyEvent moveR = new FrequencyEvent(0);
                moveR.add(new Velocity(selectedGameObj, new PVector(500,0)));
                frequencyEvents.add(moveR);
                break;

            case '1':
                print("move left");
                FrequencyEvent moveL = new FrequencyEvent(0);
                moveL.add(new Velocity(selectedGameObj, new PVector(-500,0)));
                frequencyEvents.add(moveL);
                break;
        }
        // if ((key=='s')&&(selectedGameObj!=null)){
        //      keyEvents['s'].add(new Spawn(selectedGameObj, world));
        // }
        // else if ((key=='x')&&(selectedGameObj!=null)){
        //     print("new collision \n");
        //     CollisionEvent c = new CollisionEvent(Integer.toString(selectedGameObj.getID()));
        //     c.add(new Animate(selectedGameObj, gameObjs.get(1).getRaster(),0.5));
        //     //c.add(new Spawn(selectedGameObj, world));
        //     collisionEvents.add(c);
        // }
        // else if ((key=='f')&&(selectedGameObj!=null)){
        //     print("new frequency \n");
        //     FrequencyEvent threeSeconds = new FrequencyEvent(1.5);
        //     threeSeconds.add(new Spawn(selectedGameObj, world));
        //     FrequencyEvent ongoing = new FrequencyEvent(0);
        //     ongoing.add(new Speed(selectedGameObj, 500.0, new PVector(1,0)));
        //     frequencyEvents.add(threeSeconds);
        //     frequencyEvents.add(ongoing);
        // }
        // else if ((key=='r')&&(selectedStrokes.size()>0)){
        //     selectedStrokes.createRaster(newFrame,
        //         new PVector(selectedStrokes.getLeft(), selectedStrokes.getTop()), 4);
        // }
        // else if ((key=='a')&&(selectedGameObj!=null)){
        //     print("new collision + animate");
        //     CollisionEvent c = new CollisionEvent()
        //     c.add(new Animate(selectedGameObj, gameObjs.get(1).getRaster(), 0.5));
        // }
    }

    else if ((!playing)&&selectedStrokes.getSize()>0){
        //create animation frame
        if (key=='k'){
            print("new keyframe");
            newFrame = createGraphics((int)(selectedStrokes.getRight()-selectedStrokes.getLeft()+4),
                (int)(selectedStrokes.getBottom()-selectedStrokes.getTop()+4));
            selectedStrokes.createRaster(newFrame,new PVector(selectedStrokes.getLeft(), selectedStrokes.getTop()), 4);
        }
    }

    //for  key events
    else setKeyState(true);
}

public void keyReleased(){
    if (playing) setKeyState(false);
}

public void contactStarted(FContact contact){
    currentContact = contact;
    for (CollisionEvent c : collisionEvents){
        if (c.isSingleBodied()&&currentContact.contains(c.getBody1())){
            c.set(true);
            c.set(false);
        }
        else if (currentContact.contains(c.getBody1(), c.getBody2())){
            print("dual collision \n");
            c.set(true);
            c.set(false);
        }
    }
}

public void contactEnd(FContact contact){
    //currentContact = null;
}