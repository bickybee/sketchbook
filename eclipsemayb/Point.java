import org.dyn4j.*;
import org.dyn4j.geometry.*;
import org.dyn4j.geometry.decompose.*;

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

    void translate(float xOff, float yOff){
        coords.add(xOff, yOff, 0);
    }
    
    public float getX(){
        return coords.x;
    }
    
    public float getY(){
        return coords.y;
    }

    public PVector getCoords(){
        return coords;
    }

    public float getWeight(){
        return weight;
    }
}
