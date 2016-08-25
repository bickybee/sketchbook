import fisica.*;

//Game Object
//Keeps stroke and game data
class GameObj{

  //padding required to account for stroke width
  static final float RASTER_PADDING = 4f;

	private StrokeGroup strokeGroup; 
  private PGraphics raster;
  private ArrayList<PGraphics> frames;

  private FBody templateBody; //template templateBody
  private ArrayList<FBody> bodies; //if there are duplicate bodies
  private Point[] convexHull;
  private int id;
  private float w, h;
  private PVector position; //position in editing mode
  private PVector rasterPosition;
  private CheckBox ui; //attribute editor ui
  private Button selectBtn; //used to select object for editing
  private float initialDensity;
  private ArrayList<Behaviour> behaviours;

  //some attribute bools
  private  boolean pickup, visible, slippery, bouncy, isInWorld, selected, gravity;

	GameObj(int i, StrokeGroup sg, FWorld world, ControlP5 cp5){
    id = i;
    strokeGroup = sg;

    //label strokes as belonging to this game object
    for (Stroke s: strokeGroup.getMembers()) s.addToGameObj(id, this);
    w = strokeGroup.getRight() - strokeGroup.getLeft();
    h = strokeGroup.getBottom() - strokeGroup.getTop();
    raster = createGraphics((int)(w+RASTER_PADDING),(int)(h+RASTER_PADDING));
    templateBody = setupBody(false);
    bodies = new ArrayList<FBody>();
    behaviours = new ArrayList<Behaviour>();
    position = new PVector(strokeGroup.getLeft(), strokeGroup.getTop());
    rasterPosition = new PVector(position.x, position.y);

    pickup = false;
    visible = true;
    slippery = false;
    bouncy = false;
    isInWorld = true;
    selected = false;
    gravity = false;
    initialDensity = templateBody.getDensity();
    setupRaster();
    setupMenu(Integer.toString(id), cp5);

	}

///////////////////////////////////////////////
// drawing
//////////////////////////////////////////////

  //for each world.step, move raster position to game position
  public void update(){
    for (FBody b : bodies){
      if (gravity) b.addImpulse(0, 200);
    }
  }

  //draw the sprite where the templateBody is
  public void draw(){
    for (FBody b : bodies){
      image(raster, b.getX()+position.x, b.getY()+position.y);
    }
  }

  public void draw(FBody b){
    if (visible&&isInWorld){
      image(raster, b.getX()+position.x, b.getY()+position.y);
    }
  }

  //draw vector strokeGroup onto raster sprite
  private void setupRaster(){
    strokeGroup.createRaster(raster, rasterPosition, RASTER_PADDING/2);
  }

///////////////////////////////////////////////
// stroke editing
//////////////////////////////////////////////

  public void removeStroke(Stroke s){
    s.removeFromGameObj();
    strokeGroup.removeMember(s);
    if (strokeGroup.getSize()>0) recalculateStrokeDependentData();
  }

  public void addStroke(Stroke s){
    s.addToGameObj(id, this);
    strokeGroup.addMember(s);
    recalculateStrokeDependentData();
  }

  public void updateStrokes(){
    strokeGroup.update();
    recalculateStrokeDependentData();
  }

  //when messing with the strokes in the strokegroup, we need to update geometry accordingly
  private void recalculateStrokeDependentData(){
    position = new PVector(strokeGroup.getLeft(), strokeGroup.getTop());
    w = strokeGroup.getRight() - strokeGroup.getLeft();
    h = strokeGroup.getBottom() - strokeGroup.getTop();
    raster = createGraphics((int)(w+RASTER_PADDING),(int)(h+RASTER_PADDING));
    convexHull = null;
    newTemplateBody(ui.getState(2)); //should probably use a bool
    rasterPosition = new PVector(position.x, position.y);
    setupRaster();
    ui.getParent().setPosition(position.x+77, position.y+h+20);
    selectBtn.setPosition(position.x, position.y+h);
  }

///////////////////////////////////////////////
// physics templateBody creation/updating
//////////////////////////////////////////////

  //setup physics templateBody for gameobj
  //if isExact, use the precise points to create the templateBody as a series of lines
  //otherwise create a wrapping polygon
  private FBody setupBody(boolean isExact){
    FBody b;
    if (isExact) b = createLineCompound(false);
    else b = createHull();
    b.setPosition(0,0);
    b.setRotatable(false);
    b.setRestitution(0);
    b.setFriction(10);
    b.setDamping(0);
    return b;
  }

//use giftwrap algorithm to create convex templateBody FPoly
  private FPoly createHull(){
    GiftWrap wrapper = new GiftWrap();
    if (convexHull==null){
      ArrayList<Point> allKeyPoints = new ArrayList<Point>();
      for (Stroke s : strokeGroup.getMembers()){
        Collections.addAll(allKeyPoints, s.keyPoints);
      }
      convexHull = allKeyPoints.toArray(new Point[allKeyPoints.size()]);
    }
    return wrapper.generate(convexHull);
  }

  //string together key points to make an FCompound of FLines
  private FCompound createLineCompound(boolean isJumpThrough){
      FCompound lines = new FCompound();
      for (Stroke s: strokeGroup.getMembers()){
        int length = s.keyPoints.length;

        //need DOUBLE-SIDED LINE... creating another line in the opposite direction with offset
        //offset = normal vector at that point (averaged from neighbouring lines)
        if (s.keyPointsOffset==null) s.offsetKeyPoints();

        for (int i = 1; i < length; i++){
          lines.addBody(new FLine(s.keyPoints[i-1].getX(), s.keyPoints[i-1].getY(),s.keyPoints[i].getX(), s.keyPoints[i].getY()));
          lines.addBody(new FLine(s.keyPointsOffset[length-i].getX(), s.keyPointsOffset[length-i].getY(),
                                  s.keyPointsOffset[length-i-1].getX(), s.keyPointsOffset[length-i-1].getY()));
        }
      }
      return lines;
  }

  private void newTemplateBody(boolean isExact){
      //world.remove(templateBody);
      FBody newBody = setupBody(isExact);
      newBody.setStatic(templateBody.isStatic());
      newBody.setSensor(templateBody.isSensor());
      if (templateBody.isStatic()) newBody.setDensity(templateBody.getDensity());
      templateBody = newBody;
      setSlippery(slippery);
      setBouncy(bouncy);
  }

  public FBody spawnBody(){
    FBody spawn = copy(templateBody);
    bodies.add(spawn);
    return spawn;
  }

  public void removeBody(FBody b){
    bodies.remove(b);
  }

  public void clearBodies(){
    bodies = new ArrayList<FBody>();
  }

  public FBody copy(FBody b){
    FBody newBody;
    if (templateBody instanceof FCompound) newBody = createLineCompound(false);
    else newBody = createHull();
    newBody.setRotatable(false);
    newBody.setStatic(templateBody.isStatic());
    newBody.setSensor(templateBody.isSensor());
    newBody.setDensity(templateBody.getDensity());
    newBody.setFriction(slippery ? 0 : 10);
    newBody.setRestitution(bouncy ? 1 : 0);
    newBody.setDamping(0);
    newBody.setName(Integer.toString(id));
    return newBody;
  }


///////////////////////////////////////////////
// setting attributes & behaviours
//////////////////////////////////////////////

  public void setStatic(boolean state){
    if (state!=templateBody.isStatic()) templateBody.setStatic(state);
  }

  public void setSolid(boolean state){
    if (state!=templateBody.isSensor()) templateBody.setSensor(state);
  }

  public void setExact(boolean state){
    if ((state&&(templateBody instanceof FPoly))||(!state)&&(templateBody instanceof FCompound)){ 
      newTemplateBody(state);
    }
  }

  public void setMassive(boolean state){
    if (state) templateBody.setDensity(500);
    else templateBody.setDensity(initialDensity);
  }

  public void setBouncy(boolean state){
    bouncy = state;
    if (bouncy) templateBody.setRestitution(1);
    else templateBody.setRestitution(0);
  }

  public void setSlippery(boolean state){
    slippery = state;
    if (slippery) templateBody.setFriction(0);
    else templateBody.setFriction(10);
  }

  public void setGravity(boolean state){
    gravity = state;
  }


///////////////////////////////////////////////
// menu setup/listeners
//////////////////////////////////////////////

    //setup attributes menu
  private void setupMenu(String id, ControlP5 cp5){
    Group menu = cp5.addGroup("attributes_"+id).setBackgroundColor(color(0, 64))
    .setPosition(position.x+77, position.y+h+20)
    .setHeight(20)
    .setWidth(75)
    .close();

    ui = cp5.addCheckBox("checkbox"+id)
   .setPosition(0,0)
   .setItemWidth(20)
   .setItemHeight(20)
   .addItem("static_"+id, 1)
   .addItem("sensor_"+id, 2)
   .addItem("exact_"+id, 3)
   .addItem("massive_"+id, 4)
   .addItem("bouncy_"+id, 5)
   .addItem("slippery_"+id, 6)
   .addItem("controllable_"+id, 7)
   .addItem("gravity_"+id,8)
   .setColorLabel(color(0))
   .moveTo(menu);

   selectBtn = cp5.addButton("edit_strokes_"+id)
      .setPosition(position.x,position.y+h)
      .setHeight(20)
      .setWidth(75);
  }

  public void updateAttributes(){
    setStatic(ui.getState(0));
    setSolid(ui.getState(1));
    setExact(ui.getState(2));
    setMassive(ui.getState(3));
    setBouncy(ui.getState(4));
    setSlippery(ui.getState(5));
    setGravity(ui.getState(7));
  }

  //for switching between paint and play mode-- restart play
  public void revert(){
    templateBody.recreateInWorld();
    templateBody.setVelocity(0,0);
    templateBody.setPosition(0,0);
    update();
  }

///////////////////////////////////////////////
// getters and setters
//////////////////////////////////////////////

  public FBody getBody(){
    return templateBody;
  }

  public ArrayList<FBody> getBodies(){
    return bodies;
  }

  public void resetBodies(){
    for (int i = bodies.size()-1; i == 0; i--){
      bodies.remove(i);
    }
  }

  public void setRaster(PGraphics newRaster){
    raster = newRaster;
  }

  public PGraphics getRaster(){
    return raster;
  }

  public StrokeGroup getStrokes(){
    return strokeGroup;
  }

  public CheckBox getUI(){
    return ui;
  }

  public Button getSelectBtn(){
    return selectBtn;
  }

  public void hideUI(){
    ui.getParent().hide();
    selectBtn.hide();
  }

  public void showUI(){
    ui.getParent().show();
    selectBtn.show();
  }

  public void select(){
    selected = true;
  }

  public void deselect(){
    selected = false;
  }

  public boolean isSelected(){
    return selected;
  }

  public int getID(){
    return id;
  }

  public float getInitialDensity(){
    return initialDensity;
  }

}