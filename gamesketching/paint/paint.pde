import com.goebl.simplify.*;
import codeanticode.tablet.*;
import controlP5.*;
import java.awt.geom.*;
import fisica.*;
import java.lang.reflect.*;


//canvas stuff
Tablet tablet;
ArrayList<Point> currentStroke;
StrokeGroup canvasStrokes;
color currentColour;
color bg;
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
FContact currentContact;

void setup() {
    fullScreen(2);
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
    currentContact = new FContact();
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

    background(bg);
}

//drawing loop
void draw() {

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
                obj.getBody().setDensity(obj.getInitialDensity());              
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
    if (key=='n'){
        world.add(gameObjs.get(0).spawnBody());
    }
    setKeyState(true);
}

public void keyReleased(){
    setKeyState(false);
}

public void contactStarted(FContact contact){
    currentContact = contact;
}

public void contactEnd(FContact contact){
    currentContact = null;
}