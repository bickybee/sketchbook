import org.dyn4j.*;
import org.dyn4j.geometry.*;
import org.dyn4j.geometry.decompose.*;

class Point{
    
    float weight;
    PVector coords;

    Point(PVector p){
        coords = new PVector(p.x, p.y);
    }

    Point(float x, float y){
        coords = new PVector(x, y);
    }

    Point(float x, float y, float w){
        coords = new PVector(x, y);
        weight = w;
    }

    void translate(float xOff, float yOff){
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
