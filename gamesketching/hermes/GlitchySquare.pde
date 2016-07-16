static final int SHAKE_STEP = 10;

class Player extends Being {
    int w = 50;
    int h = 50;
    int r = 5;
    boolean _stroke, _up, _down, _left, _right;


    Player(int x, int y, int r) {
        super(new HCircle(x, y, r));
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
    _stroke = false;
  }

    public void draw() {
        noFill();
          strokeWeight(5);
          stroke(200);
        _shape.draw();
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