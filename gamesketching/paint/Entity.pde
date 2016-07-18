import org.dyn4j.*;
import org.dyn4j.geometry.hull.*;

class Entity{

	StrokeGroup strokes;
  Polygon hull;
  int id;

	Entity(int i, StrokeGroup sg){
    id = i;
    strokes = sg;
    hull = sg.convexHull();
	}

  public void drawHull() {
    drawPolygon(hull);
  }

  public void draw(){
    drawHull();
  }

  public void translate(float dx, float dy){
      strokes.translate(dx, dy); //hull moves with stroke points!!!!!!
  }

}