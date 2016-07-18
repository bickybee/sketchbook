import com.goebl.simplify.*;
import codeanticode.tablet.*;
import controlP5.*;
import java.awt.geom.*;
import org.dyn4j.*;
import org.dyn4j.geometry.*;

//canvas stuff
Tablet tablet;
ArrayList<Point> currentStroke;
ArrayList<Stroke> allStrokes;
color currentColour;
color bg;
StrokeGroup selectedStrokes;

//penStuff
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
Button objBtn;
RadioButton modeRadio;
RadioButton colourRadio;
RadioButton layerRadio;

//GAME STUFF!!!!!!!
ArrayList<Entity> entities;
Player player;
//Player player;

//any initialization goes here
void setup() {
    fullScreen(2); //fullscreen on second screen (tablet)
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
    modeRadio = gui.addRadioButton("mode")
                .setPosition(0,buttonH*6+20)
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

    tablet = new Tablet(this);
    bg = color(255);
    currentColour = color(0,0,0);
    currentStroke = new ArrayList<Point>();
    allStrokes = new ArrayList<Stroke>();
    selectedStrokes = new StrokeGroup();
    //
    penIsDown = false;
    penMode = Mode.DRAW;
    translating = false;
    //
    entities = new ArrayList<Entity>();
    background(bg);
}

//drawing loop
//basically the tablet-input handler
void draw() {
     
    if (tablet.isLeftDown()&&mouseX>buttonW) penDown();
    else if (!tablet.isLeftDown() && penIsDown) penUp();
    else penHover();

    penSpeed = abs(mouseX-pmouseX) + abs(mouseY-pmouseY);
    tablet.saveState();

}

void keyPressed(){
    if (player!=null){
        player.keyPressed();
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
            player = new Player(0, selectedStrokes);
            entities.add(player);
            deselectStrokes();
            reDraw();
        }
    }

    //CREATE GAME OBJ

    //MODES
    else if (e.isFrom(modeRadio)){
        switch ((int)e.getValue()){

            //DRAW
            case 1:
                deselectStrokes();
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


