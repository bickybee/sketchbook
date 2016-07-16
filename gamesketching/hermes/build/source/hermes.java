import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import hermes.*; 
import hermes.hshape.*; 
import hermes.animation.*; 
import hermes.physics.*; 
import hermes.postoffice.*; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class hermes extends PApplet {

/**
 * A template to get you started
 * Define your beings, groups, interactors and worlds in separate tabs
 * Put the pieces together in this top-level file!
 *
 * See the tutorial for details:
 * https://github.com/rdlester/hermes/wiki/Tutorial-Pt.-1:-Worlds-and-Beings
 */







///////////////////////////////////////////////////
// CONSTANTS
///////////////////////////////////////////////////
/**
 * Constants should go up here
 * Making more things constants makes them easier to adjust and play with!
 */
static final int WINDOW_WIDTH = 600;
static final int WINDOW_HEIGHT = 600;
static final int PORT_IN = 8080;
static final int PORT_OUT = 8000; 

World currentWorld;

///////////////////////////////////////////////////
// PAPPLET
///////////////////////////////////////////////////

public void setup() {
  size(WINDOW_WIDTH, WINDOW_HEIGHT); 
  Hermes.setPApplet(this);

  currentWorld = new TemplateWorld(PORT_IN, PORT_OUT);       

  //Important: don't forget to add setup to TemplateWorld!

  currentWorld.start(); // this should be the last line in setup() method
}

public void draw() {
  currentWorld.draw();
}
/**
 * Synchronizes the color of the GlitchySquares
 */
class GlitchyGroup extends Group<GlitchySquare> {

  GlitchyGroup(World w) {
    super(w);
  }

  public void update() {
    int c = pickColor();
    for (GlitchySquare s : getObjects()) {
      s.setColor(c);
    }
  }

  private int pickColor() {
    return color(PApplet.parseInt(random(256)), PApplet.parseInt(random(256)), PApplet.parseInt(random(256)));
  }

  public void addSquare() {
    int x = (int) random(WINDOW_WIDTH - 50);
    int y = (int) random(WINDOW_HEIGHT - 50);
    GlitchySquare s = new GlitchySquare(x, y);
    _world.register(s);
    add(s);

    _world.subscribe(s, POCodes.Key.UP);
    _world.subscribe(s, POCodes.Key.RIGHT);
    _world.subscribe(s, POCodes.Key.DOWN);
    _world.subscribe(s, POCodes.Key.LEFT);
    _world.subscribe(s, POCodes.Button.LEFT, s.getShape());
  }

  public void receive(KeyMessage m) {
    if (m.isPressed()) {
      addSquare();
    }
  }

}
static final int SHAKE_STEP = 10;

class GlitchySquare extends Being {
    static final int WIDTH = 50;
    static final int HEIGHT = 50;
    int _c;
    boolean _stroke, _up, _down, _left, _right;


    GlitchySquare(int x, int y) {
        super(new HRectangle(x, y, WIDTH, HEIGHT));
        pickColor();
        _stroke = false;
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
        fill(_c);
        if (_stroke){
          strokeWeight(5);
          stroke(255);
        }
        else{
          noStroke();
        }
        _shape.draw();
    }

    public void drawStroke(){
      _stroke = true;
    }

    private void pickColor() {
        //_c = color(int(random(256)), int(random(256)), int(random(256)));
    }

    public void setColor(int c){
      _c = c;
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

public void receive(MouseMessage m) {
  if (m.getAction() == POCodes.Click.PRESSED) {
    currentWorld.delete(this);
  }
}
    
}
/**
 * When two GlitchySquares overlap,
 * draw a border around them
 */
class SquareInteractor extends Interactor<GlitchySquare, GlitchySquare> {
    SquareInteractor() {
        super();
    }

    public boolean detect(GlitchySquare being1, GlitchySquare being2) {
        return being1.getShape().collide(being2.getShape());
    }

    public void handle(GlitchySquare being1, GlitchySquare being2) {
        being1.drawStroke();
        being2.drawStroke();
    }
}
/**
 * Template being
 */
class TemplateBeing extends Being {
  TemplateBeing(HShape shape) {
    super(shape);
    //Add your constructor info here
  }

  public void update() {
    // Add update method here
  }

  public void draw() {
    // Add your draw method here
  }
}
static final int SQUARE_NUM = 10;

class TemplateWorld extends World {
  TemplateWorld(int portIn, int portOut) {
    super(portIn, portOut);
  }

  public void draw() {
    background(0);
    super.draw();
}

  public void setup() {
    GlitchyGroup g = new GlitchyGroup(this);
    register(g);
        for (int i = 0; i < SQUARE_NUM; i++) {
	        g.addSquare();
    }
    register(g,g,new SquareInteractor());
    subscribe(g, POCodes.Key.A);
  }
}
    static public void main(String[] passedArgs) {
        String[] appletArgs = new String[] { "hermes" };
        if (passedArgs != null) {
          PApplet.main(concat(appletArgs, passedArgs));
        } else {
          PApplet.main(appletArgs);
        }
    }
}
