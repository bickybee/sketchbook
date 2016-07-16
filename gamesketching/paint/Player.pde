static final int SHAKE_STEP = 10;

class Player extends Being {
    boolean _stroke, _up, _down, _left, _right;
    StrokeGroup strokes;


    Player(StrokeGroup sg) {
      strokes = sg;
        super(new HPolygon(new PVector((sg.getRight()-sg.getLeft())/2, (sg.getBottom()-sg.getTop())/2), sg.convexHull()));
        _up = false;
        _down = false;
        _left = false;
        _right = false;
    }

  public void update() {
    if (_up) {
      _position.y -= SHAKE_STEP;
    } 
    if (_right) {
      _position.x += SHAKE_STEP;
    } 
    if (_down) {
      _position.y += SHAKE_STEP;
    } 
    if (_left) {
      _position.x -= SHAKE_STEP;
    }
  }

    public void draw() {
        strokes.draw();
    }


public void receive(KeyMessage m) {
  int code = m.getKeyCode();
  if (m.isPressed()) {
    if (code == POCodes.Key.UP) {
      _up = true;
    } 
    else if (code == POCodes.Key.RIGHT) {
      _right = true;
    } 
    else if (code == POCodes.Key.DOWN) {
      _down = true;
    } 
    else if (code == POCodes.Key.LEFT) {
      _left = true;
    }
  } 
  else {
    if (code == POCodes.Key.UP) {
      _up = false;
    } 
    else if (code == POCodes.Key.RIGHT) {
      _right = false;
    } 
    else if (code == POCodes.Key.DOWN) {
      _down = false;
    } 
    else if (code == POCodes.Key.LEFT) {
      _left = false;
    }
  }
}

    
}