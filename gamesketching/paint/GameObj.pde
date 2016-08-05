import fisica.*;

//Game object class
//Keeps stroke and game data
class GameObj{

  //padding required to account for stroke width
  static final float RASTER_PADDING = 2f;

	StrokeGroup strokeGroup; //vector stroke group
  PGraphics raster; //raster of vector strokeGroup, for rendering efficiency during gameplay
  FBody body; //physics body
  int id;
  float w, h;
  PVector gamePosition; //position in gameplay mode
  PVector paintPosition; //position in editing mode
  CheckBox ui; //attribute editor ui
  Button selectBtn; //used to select object for editing

  //some attribute bools
  boolean pickup, visible, slippery, bouncy, isInWorld, selected;

	GameObj(int i, StrokeGroup sg, FWorld world, ControlP5 cp5){
    id = i;
    strokeGroup = sg;

    //label strokes as belonging to this game object
    for (Stroke s: strokeGroup.getMembers()) s.addToGameObj(id, this);

    gamePosition = new PVector(strokeGroup.getLeft(), strokeGroup.getTop());
    w = strokeGroup.getRight() - strokeGroup.getLeft();
    h = strokeGroup.getBottom() - strokeGroup.getTop();
    raster = createGraphics((int)(w+RASTER_PADDING),(int)(h+RASTER_PADDING));
    body = setupBody(false);
    paintPosition = new PVector(gamePosition.x, gamePosition.y);

    pickup = false;
    visible = true;
    slippery = false;
    bouncy = false;
    isInWorld = true;
    selected = false;
    setupRaster();
    setupMenu(Integer.toString(id), cp5);

	}

  //for each world.step, move raster gamePosition to body gamePosition
  public void update(){
    gamePosition.x = body.getX()+paintPosition.x;
    gamePosition.y = body.getY()+paintPosition.y;
    if (pickup){
      if (body.getContacts().size()!=0){//for now, pickups disappear upon contact with any body
        world.remove(body);
        isInWorld = false;
      }
    }
  }

  public void removeStroke(Stroke s){
    strokeGroup.removeMember(s);
    if (strokeGroup.getSize()>0) recalculateStrokeDependentData();
  }

  public void addStroke(Stroke s){
    strokeGroup.addMember(s);
    recalculateStrokeDependentData();
  }

  public void updateStrokes(){
    strokeGroup.update();
    recalculateStrokeDependentData();
  }

  //when messing with the strokes in the strokegroup, we need to update geometry accordingly
  void recalculateStrokeDependentData(){
    gamePosition = new PVector(strokeGroup.getLeft(), strokeGroup.getTop());
    w = strokeGroup.getRight() - strokeGroup.getLeft();
    h = strokeGroup.getBottom() - strokeGroup.getTop();
    raster = createGraphics((int)(w+RASTER_PADDING),(int)(h+RASTER_PADDING));
    paintPosition = new PVector(gamePosition.x, gamePosition.y);
    newBody(ui.getState(2)); //should probably use a bool
    setupRaster();
    ui.getParent().setPosition(paintPosition.x+77, paintPosition.y+h+20);
    selectBtn.setPosition(paintPosition.x, paintPosition.y+h);
  }

  //draw vector strokeGroup onto raster sprite
  public void setupRaster(){
    for (Stroke s: strokeGroup.getMembers()){
      s.draw(raster, gamePosition, RASTER_PADDING/2);
    }
  }

  //setup physics body for gameobj
  //if isExact, use the precise points to create the body as a series of lines
  //otherwise create a wrapping polygon
  public FBody setupBody(boolean isExact){
    FBody b;
    if (isExact) b = createLineCompound(false);
    else b = createHull();
    b.setPosition(0,0);
    b.setRotatable(false);
    b.setRestitution(0);
    b.setFriction(100);
    return b;
  }

//use giftwrap algorithm to create convex body FPoly
  public FPoly createHull(){
    GiftWrap wrapper = new GiftWrap();
    Point[] input = strokeGroup.getKeyPoints().toArray(new Point[strokeGroup.getKeyPointsSize()]);
    return wrapper.generate(input);
  }

  //string together key points to make a big line body
  public FCompound createLineCompound(boolean isJumpThrough){
      FCompound lines = new FCompound();
      for (Stroke s: strokeGroup.getMembers()){
        for (int i = 1; i < s.keyPoints.length; i++){
          lines.addBody(new FLine(s.keyPoints[i-1].getX(), s.keyPoints[i-1].getY(),s.keyPoints[i].getX(), s.keyPoints[i].getY()));
        }
        //for some reason collision is only detected one way, so here's how to get two way:
        //NVM things just get stuck :-(
        // if (!isJumpThrough){
        //   for (int i = s.keyPoints.length-1; i >= 1; i--){
        //     lines.addBody(new FLine(s.keyPoints[i].getX(), s.keyPoints[i].getY(),s.keyPoints[i-1].getX(), s.keyPoints[i-1].getY()));
        //   }
        // }
      }
      return lines;
  }


  //draw the sprite where the body is
  public void draw(){
    if (visible&&isInWorld) image(raster,gamePosition.x, gamePosition.y);
  }

  //not in use currently...
  public void translate(float dx, float dy){
      gamePosition.add(dx,dy);
      //strokeGroup.translate(dx, dy); //body moves with stroke points!!!!!!
  }

  public void setStatic(boolean state){
    if (state!=body.isStatic()) body.setStatic(state);
    print("static "+body.isStatic()+"\n");
  }

  public void setSolid(boolean state){
    if (state!=body.isSensor()) body.setSensor(state);
    print("sensor "+body.isSensor()+"\n");
  }

  public void setExact(boolean state){
    if ((state&&(body instanceof FPoly))||(!state)&&(body instanceof FCompound)){ 
      newBody(state);
    }
  }

  public void keyHandler(int key){

  }

  public void newBody(boolean isExact){
      world.remove(body);
      FBody newBody = setupBody(isExact);
      newBody.setStatic(body.isStatic());
      newBody.setSensor(body.isSensor());
      body = newBody;
      setSlippery(slippery);
      setBouncy(bouncy);
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
    else body.setFriction(100);
  }

    //setup attributes menu
  void setupMenu(String id, ControlP5 cp5){
    Group menu = cp5.addGroup("attributes_"+id).setBackgroundColor(color(0, 64))
    .setPosition(paintPosition.x+77, paintPosition.y+h+20)
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
   .setColorLabel(color(0))
   .moveTo(menu);

   selectBtn = cp5.addButton("select_"+id)
      .setPosition(paintPosition.x,paintPosition.y+h)
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

}