import fisica.*;

//Game Object
//Keeps stroke and game data
class GameObj{

  //padding required to account for stroke width
  static final float RASTER_PADDING = 4f;

	private StrokeGroup strokeGroup; 
  private PGraphics raster;
  private FBody body; 
  private ArrayList<FBody> bodies; //if there are duplicate bodies
  private int id;
  private float w, h;
  private PVector position; //position in editing mode
  private PVector rasterPosition;
  private CheckBox ui; //attribute editor ui
  private Button selectBtn; //used to select object for editing
  private Method[] keyListeners;
  private float initialDensity;

  //some attribute bools
  private  boolean pickup, visible, slippery, bouncy, isInWorld, selected;

	GameObj(int i, StrokeGroup sg, FWorld world, ControlP5 cp5){
    id = i;
    strokeGroup = sg;

    //label strokes as belonging to this game object
    for (Stroke s: strokeGroup.getMembers()) s.addToGameObj(id, this);
    keyListeners = new Method[200];
    w = strokeGroup.getRight() - strokeGroup.getLeft();
    h = strokeGroup.getBottom() - strokeGroup.getTop();
    raster = createGraphics((int)(w+RASTER_PADDING),(int)(h+RASTER_PADDING));
    body = setupBody(false);
    bodies = new ArrayList<FBody>();
    position = new PVector(strokeGroup.getLeft(), strokeGroup.getTop());
    rasterPosition = new PVector(position.x, position.y);

    pickup = false;
    visible = true;
    slippery = false;
    bouncy = false;
    isInWorld = true;
    selected = false;
    initialDensity = body.getDensity();
    setupRaster();
    setupMenu(Integer.toString(id), cp5);

	}

///////////////////////////////////////////////
// drawing
//////////////////////////////////////////////

  //for each world.step, move raster position to game position
  public void update(){
    rasterPosition.x = body.getX()+position.x;
    rasterPosition.y = body.getY()+position.y;
    if (pickup){
      if (body.getContacts().size()!=0){//for now, pickups disappear upon contact with any body
        world.remove(body);
        isInWorld = false;
      }
    }
  }

  //draw the sprite where the body is
  public void draw(){
    if (visible&&isInWorld) image(raster,rasterPosition.x, rasterPosition.y);
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
    newBody(ui.getState(2)); //should probably use a bool
    rasterPosition = new PVector(position.x, position.y);
    setupRaster();
    ui.getParent().setPosition(position.x+77, position.y+h+20);
    selectBtn.setPosition(position.x, position.y+h);
  }

///////////////////////////////////////////////
// physics body creation/updating
//////////////////////////////////////////////

  //setup physics body for gameobj
  //if isExact, use the precise points to create the body as a series of lines
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

//use giftwrap algorithm to create convex body FPoly
  private FPoly createHull(){
    GiftWrap wrapper = new GiftWrap();
    ArrayList<Point> allKeyPoints = new ArrayList<Point>();
    for (Stroke s : strokeGroup.getMembers()){
      Collections.addAll(allKeyPoints, s.keyPoints);
    }
    Point[] input = allKeyPoints.toArray(new Point[allKeyPoints.size()]);
    return wrapper.generate(input);
  }

  //string together key points to make a big line body
  private FCompound createLineCompound(boolean isJumpThrough){
      FCompound lines = new FCompound();
      for (Stroke s: strokeGroup.getMembers()){
        for (int i = 1; i < s.keyPoints.length; i++){
          lines.addBody(new FLine(s.keyPoints[i-1].getX(), s.keyPoints[i-1].getY(),s.keyPoints[i].getX(), s.keyPoints[i].getY()));
          //need DOUBLE-SIDED LINE... creating another line in the opposite direction with a slight offset works for simple lines
          //lines.addBody(new FLine(s.keyPoints[s.keyPoints.length-i].getX(), s.keyPoints[s.keyPoints.length-i].getY()+5,
           //                       s.keyPoints[s.keyPoints.length-i-1].getX(), s.keyPoints[s.keyPoints.length-i-1].getY()+5));
          //how about other shapes? circles with interiors? :/
        }
      }
      return lines;
  }

  private void newBody(boolean isExact){
      world.remove(body);
      FBody newBody = setupBody(isExact);
      newBody.setStatic(body.isStatic());
      newBody.setSensor(body.isSensor());
      if (body.isStatic()) newBody.setDensity(body.getDensity());
      body = newBody;
      setSlippery(slippery);
      setBouncy(bouncy);
  }


///////////////////////////////////////////////
// setting attributes & behaviours
//////////////////////////////////////////////

  public void setStatic(boolean state){
    if (state!=body.isStatic()) body.setStatic(state);
  }

  public void setSolid(boolean state){
    if (state!=body.isSensor()) body.setSensor(state);
  }

  public void setExact(boolean state){
    if ((state&&(body instanceof FPoly))||(!state)&&(body instanceof FCompound)){ 
      newBody(state);
    }
  }

  public void setPickup(boolean state){
    pickup = state;
  }

  public void setBouncy(boolean state){
    bouncy = state;
    if (bouncy) body.setRestitution(1);
    else body.setRestitution(0);
  }

  public void setSlippery(boolean state){
    slippery = state;
    if (slippery) body.setFriction(0);
    else body.setFriction(10);
  }

///////////////////////////////////////////////
// behaviours
//////////////////////////////////////////////

  public void moveUp(boolean move){
    if (move) body.setVelocity(body.getVelocityX(),-500);
    else body.setVelocity(body.getVelocityX(), 0);
  }

  public void moveDown(boolean move){
    if (move) body.setVelocity(body.getVelocityX(),500);
    else body.setVelocity(body.getVelocityX(), 0);
  }

  public void moveRight(boolean move){
    if (move) body.setVelocity(500,body.getVelocityY());
    else body.setVelocity(0, body.getVelocityY());
  }

  public void moveLeft(boolean move){
    if (move) body.setVelocity(-500,body.getVelocityY());
    else body.setVelocity(0, body.getVelocityY());
  }

  public void testMethod(boolean keyPushed){
    if (keyPushed) print("method invoked true \n");
    else print("method invoked false \n");
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
   .addItem("pickup_"+id, 4)
   .addItem("bouncy_"+id, 5)
   .addItem("slippery_"+id, 6)
   .addItem("controllable_"+id, 7)
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
    setPickup(ui.getState(3));
    setBouncy(ui.getState(4));
    setSlippery(ui.getState(5));
  }

  //for switching between paint and play mode-- restart play
  public void revert(){
    body.recreateInWorld();
    body.setVelocity(0,0);
    body.setPosition(0,0);
    update();
  }

///////////////////////////////////////////////
// key listening
//////////////////////////////////////////////

  public void bindMethodToKey(Method method, int keyVal){
    keyListeners[keyVal] = method;
  }

  public void removeKeyBinding(int keyVal){
    keyListeners[keyVal] = null;
  }

  //receive notifications from keys
  public void notify(boolean isPushed, int keyVal){
    if (keyListeners[keyVal]!=null){
      try {
        keyListeners[keyVal].invoke(this, isPushed);
      } catch (Exception e){
        print(e+" from GameObj notify \n");
      }
    }
  }

///////////////////////////////////////////////
// getters and setters
//////////////////////////////////////////////

  public FBody getBody(){
    return body;
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