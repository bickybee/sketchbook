import org.dyn4j.*;
import org.dyn4j.geometry.*;
import org.dyn4j.geometry.decompose.*;

class Point{
    
    float weight;
    PVector coords;
    Vector2 coordsV2;


    Point(float x, float y){
        coords = new PVector(x, y);
        coordsV2 = new Vector2((double) x, (double) y);
    }

    Point(float x, float y, float w){
        coords = new PVector(x, y);
        coordsV2 = new Vector2((double) x, (double) y);
        weight = w;
    }

    void translate(float xOff, float yOff){
        coords.add(xOff, yOff, 0);
        coordsV2.add(xOff, yOff);
    }
    
    public float getX(){
        return coords.x;
    }
    
    public float getY(){
        return coords.y;
    }

    public Vector2 getVector2(){
        return coordsV2;
    }

    public PVector getCoords(){
        return coords;
    }

    public float getWeight(){
        return weight;
    }
}
