import fisica.*;

//Game object class
class GameObj{

  //padding required to account for stroke width
  static final float RASTER_PADDING = 2f;

	StrokeGroup strokes; //vector stroke group
  PGraphics raster; //raster of vector strokes, for rendering efficiency during gameplay
  FBody body; //physics body
  int id; //id of gameObj
  float w, h;
  PVector gamePosition; //position in gameplay mode
  PVector paintPosition; //position in editing mode
  CheckBox ui; //attribute editor ui
  Button selectBtn; //used to select object for editing

  //some attribute bools
  boolean pickup, visible, slippery, bouncy, isInWorld, selected;

	GameObj(int i, StrokeGroup sg, FWorld world, ControlP5 cp5){
    id = i;
    strokes = sg;
    gamePosition = new PVector(strokes.getLeft(), strokes.getTop());
    w = strokes.getRight() - strokes.getLeft();
    h = strokes.getBottom() - strokes.getTop();
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
    world.add(body);
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

  public void addStroke(Stroke s){
    strokes.addMember(s);
    gamePosition = new PVector(strokes.getLeft(), strokes.getTop());
    w = strokes.getRight() - strokes.getLeft();
    h = strokes.getBottom() - strokes.getTop();
    raster = createGraphics((int)(w+RASTER_PADDING),(int)(h+RASTER_PADDING));
    paintPosition = new PVector(gamePosition.x, gamePosition.y);
    newBody(ui.getState(2)); //should probably use a bool
    setupRaster();
    reDraw();
  }

  //draw vector strokes onto raster sprite
  public void setupRaster(){
    for (Stroke s: strokes.getMembers()){
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
    Point[] input = strokes.getKeyPoints().toArray(new Point[strokes.getKeyPointsSize()]);
    return wrapper.generate(input);
  }

  //string together the points to make a big line body
  public FCompound createLineCompound(boolean isJumpThrough){
      FCompound lines = new FCompound();
      for (Stroke s: strokes.getMembers()){
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
      //strokes.translate(dx, dy); //body moves with stroke points!!!!!!
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

  public void newBody(boolean isExact){
      world.remove(body);
      FBody newBody = setupBody(isExact);
      newBody.setStatic(body.isStatic());
      newBody.setSensor(body.isSensor());
      body = newBody;
      setSlippery(slippery);
      setBouncy(bouncy);
      world.add(body);
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

  public void updateStrokes(){

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
    return strokes;
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

}