import com.goebl.simplify.*;
import codeanticode.tablet.*;
import controlP5.*;
import java.awt.geom.*;
import hermes.*;
import hermes.hshape.*;
import hermes.postoffice.*;
import org.dyn4j.*;

//canvas stuff
Tablet tablet;
ArrayList<Point> currentStroke;
ArrayList<Stroke> allStrokes;
color currentColour;
color bg;
StrokeGroup selectedStrokes;

//HERMES
World world;
static final int PORT_IN = 8080;
static final int PORT_OUT = 8000; 
Player player;

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
Button playerBtn;
RadioButton modeRadio;
RadioButton colourRadio;
RadioButton layerRadio;

//any initialization goes here
void setup() {
    size(800,600); //fullscreen on second screen (tablet)
    //hermes
    Hermes.setPApplet(this);
    world = new SketchWorld(PORT_IN, PORT_OUT);       
    world.start();

    //buttons activate when you add them.... lame
    gui = new ControlP5(this);
    undoBtn = gui.addButton("undo")
        .setPosition(0,0)
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
    playerBtn = gui.addButton("undo")
        .setPosition(0,buttonH*9)
        .setSize(buttonW, buttonH)
        .activateBy(ControlP5.PRESSED);
    //instantiate stuff after adding buttons!
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
void draw() {
     
    if (tablet.isLeftDown()&&mouseX>buttonW) penDown();
    else if (!tablet.isLeftDown() && penIsDown) penUp();
    else penHover();

    penSpeed = abs(mouseX-pmouseX) + abs(mouseY-pmouseY);
    tablet.saveState();
}

void penDown(){

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

void penUp(){

    //DRAW: save finished stroke
    if (penMode==Mode.DRAW){
       Stroke finishedStroke = new Stroke(currentColour, currentStroke);
        allStrokes.add(finishedStroke); //add stroke
        reDraw();
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

void penHover(){

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


void undoStroke(){
    allStrokes.remove(allStrokes.size()-1);
    reDraw();
}

void drawAllStrokes(){
    selectedStrokes.drawBounds();
    for (Stroke selected: selectedStrokes.getMembers()){
        selected.drawSelected();
    }
    for (Stroke stroke: allStrokes){
        stroke.draw();
    }
}

void clearSelection(){
    for (Stroke s: allStrokes){
        if (s.isSelected()) s.deselect();
    }
    selectedStrokes = new StrokeGroup();
}

void eraseSelection(){
    for (Stroke s: selectedStrokes.getMembers()){
        allStrokes.remove(s); //presumably slow, but it works
    }
    selectedStrokes = new StrokeGroup();
    reDraw();
}

void reDraw(){
    background(bg);
    drawAllStrokes();
}

void draw(ArrayList<Point> points){
    stroke(currentColour);
    //strokeWeight(2);
    // noFill();
    // beginShape();
    // curveVertex(points.get(0).getX(), points.get(0).getY());
    // for (int i = 0; i < points.size(); i++){
    //     curveVertex(points.get(i).getX(), points.get(i).getY());
    // }
    // if (points.size()>1) curveVertex(points.get(points.size()-1).getX(), points.get(points.size()-1).getY());
    // endShape();
    for (int i = 1; i < points.size(); i++){
        strokeWeight(points.get(i).weight);
        line(points.get(i).getX(), points.get(i).getY(), points.get(i-1).getX(), points.get(i-1).getY());;
    }
}
