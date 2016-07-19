import org.dyn4j.*;
import org.dyn4j.geometry.hull.*;

class Entity{

	StrokeGroup strokes;
  PGraphics raster;
  Polygon hull;
  int id;
  float w, h;
  PVector position;

	Entity(int i, StrokeGroup sg){
    id = i;
    strokes = sg.copy();
    hull = strokes.convexHull();
    position = new PVector(strokes.getLeft(), strokes.getTop());
    w = strokes.getRight() - strokes.getLeft();
    h = strokes.getBottom() - strokes.getTop();
    raster = createGraphics((int)w+4,(int)h+4);
    setupRaster();
	}

  public void setupRaster(){
    for (Stroke s: strokes.getMembers()){
      s.draw(raster, position, 2f);
    }
  }

  public void drawHull() {
    drawPolygon(hull);
  }

  public void draw(){
    image(raster,position.x, position.y);
  }

  public void translate(float dx, float dy){
      position.add(dx,dy);
      //strokes.translate(dx, dy); //hull moves with stroke points!!!!!!
  }

}