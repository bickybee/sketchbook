import com.goebl.simplify.*;
import codeanticode.tablet.*;
import controlP5.*;
import java.awt.geom.*;
import fisica.*;


//canvas stuff
Tablet tablet;
ArrayList<Point> currentStroke;
ArrayList<Stroke> allStrokes;
color currentColour;
color bg;
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
ArrayList<GameObj> gameObjs;
int currentID;
GameObj selectedGameObj;
FWorld world;
boolean up, down, left, right;


//any initialization goes here
void setup() {
    fullScreen(2); 

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
    gameObjs = new ArrayList<GameObj>();
    Fisica.init(this);
    world = new FWorld();
    world.setGravity(0, 800);
    world.setEdges();

    playing = false;

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

    background(bg);
}

//drawing loop
void draw() {

    if (playing){
        world.step();
        for (GameObj obj: gameObjs) obj.update();
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

//undo stroke handler
public void undo(int val){
    if (allStrokes.size() != 0){
            undoStroke();
    }
}

//create game object handler
public void gameObj(int val){
    if (selectedStrokes.getSize() != 0){
        gameObjs.add(new GameObj(currentID++, selectedStrokes, world, gui)); //create entity
        deselectStrokes();
        reDraw();
    } 
}

//play vs. draw mode, radio handler
public void mode(int val){
    switch(val){
        case(1):
            playing = false;
            for (GameObj obj: gameObjs) obj.showUI();
            restartGame();
            reDraw();
           break;
        case(2):
            playing = true;
            for (GameObj obj: gameObjs) obj.hideUI();
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

public void colour(int val){
    currentColour = val;
    stroke(currentColour);
    if (selectedStrokes.getMembers().size()!=0){
        for (Stroke s: selectedStrokes.getMembers()){
            s.setColour(currentColour);
        }
        reDraw();
    }
}

//game object editing menu handler
public void controlEvent(ControlEvent event){
    for (GameObj obj: gameObjs){
        if (event.isFrom(obj.getUI())){
            obj.updateAttributes();
        }
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
