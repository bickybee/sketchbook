import fisica.*;

//Game object class
class Entity{

  //padding required to account for stroke width
  static final float RASTER_PADDING = 2f;

	StrokeGroup strokes;
  PGraphics raster;
  FPoly hull;
  int id;
  float w, h;
  PVector position;
  PVector initialPosition;
  Group menu;

	Entity(int i, StrokeGroup sg, FWorld world, ControlP5 cp5){
    id = i;
    strokes = sg;
    position = new PVector(strokes.getLeft(), strokes.getTop());
    w = strokes.getRight() - strokes.getLeft();
    h = strokes.getBottom() - strokes.getTop();
    raster = createGraphics((int)(w+RASTER_PADDING),(int)(h+RASTER_PADDING));
    setupRaster();
    setupHull();
    setupMenu(Integer.toString(id), cp5);
    world.add(hull);
	}

  //for each world.step, move raster position to hull position
  public void update(){
    position.x = hull.getX()+initialPosition.x;
    position.y = hull.getY()+initialPosition.y;
  }

  //draw vector strokes onto raster sprite
  public void setupRaster(){
    for (Stroke s: strokes.getMembers()){
      s.draw(raster, position, RASTER_PADDING/2);
    }
  }

  //use giftwrap algorithm to create convex hull FPoly
  public void setupHull(){
    GiftWrap wrapper = new GiftWrap();
    Point[] input = strokes.getKeyPoints().toArray(new Point[strokes.getKeyPointsSize()]);
    hull = wrapper.generate(input);
    hull.setPosition(0,0);
    hull.setRotatable(false);
    initialPosition = new PVector(position.x, position.y);
  }

  void setupMenu(String id, ControlP5 cp5){
    menu = cp5.addGroup(id).setBackgroundColor(color(0, 64));
    cp5.addCheckBox("radio"+id)
   .setPosition(0,0)
   .setItemWidth(20)
   .setItemHeight(20)
   .addItem("fixed_"+id, 0)
   .addItem("solid_"+id, 1)
   .setColorLabel(color(255))
   .moveTo(menu);
    cp5.addAccordion("acc"+id)
    .setPosition(position.x, position.y+h)
    .setWidth((int)(w))
    .setHeight(20)
    .addItem(menu);
  }

  //draw the sprite where the hull is
  public void draw(){
    image(raster,position.x, position.y);
  }

  //not in use currently...
  public void translate(float dx, float dy){
      position.add(dx,dy);
      //strokes.translate(dx, dy); //hull moves with stroke points!!!!!!
  }

  public FPoly getHull(){
    return hull;
  }

  //for switching between paint and play mode-- restart play
  public void revert(){
    hull.recreateInWorld();
    hull.setVelocity(0,0);
    hull.setPosition(0,0);
    update();
  }

  public StrokeGroup getStrokes(){
    return strokes;
  }

  public void toggleStatic(){
    hull.setStatic(!hull.isStatic());
    print(hull.isStatic()+"\n");
  }

  public void toggleSolid(){

  }

}