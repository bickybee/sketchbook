import fisica.*;

class Entity{

  static final float RASTER_PADDING = 2f;

	StrokeGroup strokes;
  PGraphics raster;
  FPoly hull;
  int id;
  float w, h;
  PVector position;
  PVector initialPosition;

	Entity(int i, StrokeGroup sg, FWorld world){
    id = i;
    sg.belongsToEntity();
    strokes = sg;
    position = new PVector(strokes.getLeft(), strokes.getTop());
    w = strokes.getRight() - strokes.getLeft();
    h = strokes.getBottom() - strokes.getTop();
    raster = createGraphics((int)(w+RASTER_PADDING/2),(int)(h+RASTER_PADDING/2));
    setupRaster();
    setupHull();
    world.add(hull);
	}

  public void update(){
    position.x = hull.getX()+initialPosition.x;
    position.y = hull.getY()+initialPosition.y;
  }

  public void setupRaster(){
    for (Stroke s: strokes.getMembers()){
      s.draw(raster, position, RASTER_PADDING);
    }
  }

  public void setupHull(){
    GiftWrap wrapper = new GiftWrap();
    Point[] input = strokes.getKeyPoints().toArray(new Point[strokes.getKeyPointsSize()]);
    hull = wrapper.generate(input);
    hull.setPosition(0,0);
    hull.setRotatable(false);
    initialPosition = new PVector(position.x, position.y);
  }

  public void draw(){
    image(raster,position.x, position.y);
  }

  public void translate(float dx, float dy){
      position.add(dx,dy);
      //strokes.translate(dx, dy); //hull moves with stroke points!!!!!!
  }

  public FPoly getHull(){
    return hull;
  }

  public void revert(){
    hull.recreateInWorld();
    hull.setVelocity(0,0);
    hull.setPosition(0,0);
    update();
  }

}