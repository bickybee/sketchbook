import codeanticode.tablet.*;
import controlP5.*;


//canvas stuff
Tablet tablet;
ArrayList<Point> currentStroke;
ArrayList<ArrayList<Point>> allStrokes;
color currentColour;
boolean drawing;
int pointIndex;

//GUI stuff 
ControlP5 gui;

//any initialization goes here
void setup() {
    size(1000, 750);
    //noLoop();
    
    tablet = new Tablet(this);
    currentStroke = new ArrayList<Point>();
    allStrokes = new ArrayList<ArrayList<Point>>();
    currentColour = color(1,1,1);
    drawing = false;
    pointIndex = 0;
    
    gui = new ControlP5(this);
    gui.addButton("undo")
        .setValue(0)
        .setPosition(0,0)
        .setSize(200,20)
        .activateBy(ControlP5.PRESSED)
        ;
    
    background(255);
}

//drawing loop
void draw() {
    stroke(255);
    //background(102); //clear
    handleTablet();
}

void drawAllStrokes(){
    for (ArrayList<Point> stroke: allStrokes){
        for (Point p: stroke){
            p.drawOntoCurrentStroke(stroke);
        }
    }
}

public void undo(){
    if (allStrokes.size() != 0){
        undoStroke();
        print("undo"+allStrokes.size()+"\n");
    }
}

void undoStroke(){
    allStrokes.remove(allStrokes.size()-1);
    background(255); 
    drawAllStrokes();
    print(allStrokes.size());    
}

//tablet input handler
void handleTablet() {

    //if pen is down/drawing
    if (tablet.isLeftDown()&&tablet.getPenY()>20) {
        
        //if pen just started drawing, create a new stroke
        if (!drawing){
            currentStroke = new ArrayList<Point>();
            drawing = true;
            pointIndex = 0;
        }
        
        //add new point to stroke
        Point currentPoint = new Point(tablet.getPenX(), tablet.getPenY(), currentColour, 5*tablet.getPressure(), pointIndex);
        currentStroke.add(currentPoint);
        currentPoint.drawOntoCurrentStroke();
        pointIndex++;
    }
    
    //if done drawing, save the stroke
    else if (drawing){
        ArrayList<Point> finishedStroke = new ArrayList<Point>();
        for (Point p: currentStroke){
            finishedStroke.add(new Point(p.x, p.y, p.colour, p.weight, p.index));
        }
        allStrokes.add(finishedStroke);
        print("drawn"+allStrokes.size()+"\n");
        drawing = false;
    }
    tablet.saveState();
}

class Point{
    
    int index; //index of point within stroke
    float x, y, weight;
    color colour;
    
    Point(float x0, float y0, color c, float w, int i){
        x = x0;
        y = y0;
        colour = c;
        weight = w;
        index = i;
    }
    
    public float getX(){
        return x;
    }
    
    public float getY(){
        return y;
    }
    
    void drawOntoCurrentStroke(){
        stroke(colour);
        strokeWeight(weight);
        line(x, y, tablet.getSavedPenX(), tablet.getSavedPenY());
    }
    
    void drawOntoCurrentStroke(ArrayList<Point> s){
        stroke(colour);
        strokeWeight(weight);
        if (index!=0) line(x, y, s.get(index-1).getX(), s.get(index-1).getY());
    }
    
}

//stroke class to contain points, color, 
class Stroke{
    ArrayList<Point> points;
    Point colour;
    float boxTR, boxBL; //bounding box coordinates
    Stroke(ArrayList p, Point c){
        points = p;
        colour = c;
    }
    
    void drawStroke(){
           
    }
    
    void simplify(){
        //simplify the points
    }
}