
static final int STEP = 10;

class HPlayer extends Being {
    boolean _stroke, _up, _down, _left, _right;
    StrokeGroup strokes;

    HPlayer(StrokeGroup sg) {
        super(new HPolygon(new PVector((sg.getRight()-sg.getLeft())/2, (sg.getBottom()-sg.getTop())/2), sg.convexHull()));
        strokes = sg;
        _up = false;
        _down = false;
        _left = false;
        _right = false;
    }

  public void update() {
    if (_up) {
      this.move(0,-STEP);
    } 
    if (_right) {
      this.move(STEP,0);
    } 
    if (_down) {
      this.move(0,STEP);
    } 
    if (_left) {
      this.move(-STEP,0);
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

public void move(int dx, int dy){
    _position.x += dx;
    _position.y += dy;
    this.strokes.translate(dx, dy);
}

    
}