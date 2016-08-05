import java.awt.geom.*;
import java.util.Arrays;

private final float TOLERANCE = 0.25;
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
    color colour;
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

    Stroke(color c, ArrayList<Point> inPoints){
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
    
    boolean addPoint(Point p, int i){
        if (size>0){
            points[i] = p;
            return true;
        }
        return false;
    }

    //draw while creating a stroke
    void draw(Tablet tab, float newX, float newY, float oldX, float oldY){
        //strokeWeight(tab.getPressure()*5);
        line(newX, newY, oldX, oldY);
    }
    
    //drawing a completed stroke
    void draw(){
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
    void draw(PGraphics pg, PVector position, float padding){
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
    void drawSelected(){
        stroke(META_COLOUR);
        strokeWeight(META_WEIGHT);
        for (int i = 1; i < size; i++){
            //strokeWeight(points[i].weight+10);
            line(points[i].getX(), points[i].getY(), points[i-1].getX(), points[i-1].getY());;
        }
    }

    void drawBounds(){
        stroke(META_COLOUR);
        strokeWeight(META_WEIGHT);
        line(left, top, right, top);
        line(right, top, right, bottom);
        line(right, bottom, left, bottom);
        line(left, bottom, left, top);
    }

    void setBounds(){
        for (int i = 0; i < size; i++){
            if (points[i].getX() < left) left = points[i].getX();
            if (points[i].getX() > right) right = points[i].getX();
            if (points[i].getY() < top) top = points[i].getY();
            if (points[i].getY() > bottom) bottom = points[i].getY();
        }
        //bloat small points?
        bloatSmallBounds(MIN_AABB_SIZE);
    }

    void bloatSmallBounds(float minSize){
        float area = (right-left)*(bottom-top);
        if (area<minSize){
            float bloat = minSize-area;
            left -= bloat;
            right += bloat;
            top -= bloat;
            bottom += bloat;
        }
    }

    boolean boundsContain(int x, int y){
        if (x > left && x < right && y > top && y < bottom) return true;
        else return false;
    }

    boolean boundsContain(float x, float y){
        if (x > left && x < right && y > top && y < bottom) return true;
        else return false;
    }

    boolean rectIntersectsLine(float l, float t, float r, float b,
        float x1, float y1, float x2, float y2){
        if (Line2D.linesIntersect(x1,y1,x2,y2,l,t,r,t) ||
            Line2D.linesIntersect(x1,y1,x2,y2,r,t,r,b) ||
            Line2D.linesIntersect(x1,y1,x2,y2,r,b,l,b) ||
            Line2D.linesIntersect(x1,y1,x2,y2,l,b,l,t)){
                return true;
        }
        else return false;
    }

    boolean boundsIntersectLine(float x1, float y1, float x2, float y2){
        return rectIntersectsLine(left, top, right, bottom, x1,y1,x2,y2);
    }

    //bounds intersect rectangle
    boolean boundsIntersectRect(float l, float t, float r, float b){
        if (bottom<t || b<top || right<l || r<left) return false;
        else return true;
    }

    //line intersection with stroke
    boolean intersects(float x1, float y1, float x2, float y2){
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


    void translate(float xOff, float yOff){
        left += xOff;
        right += xOff;
        top += yOff;
        bottom += yOff;
        for (Point p: points){
            p.translate(xOff, yOff);
        }
    }

//testing simplify library
    void simplify(float tolerance){
        points = returnSimplified(tolerance);
        size = points.length;
    }

    Point[] returnSimplified(float tolerance){
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

    public color getColour() {
        return colour;
    }

    public void setColour(color colour) {
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

    void select(){
        selected = true;
    }

    void deselect(){
        selected = false;
    }

    void addToGameObj(int id, GameObj o){
        gameObj = o;
        gameObjId = id;
        belongsToObj = true;
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