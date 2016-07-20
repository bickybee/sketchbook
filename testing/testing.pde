int numThings = 15;
int thingSize = 64;
String here = "<< here";
ThingMover thingMover;
boolean locked = false;
 
 void setup() { 
  size(800, 480);
  thingMover = new ThingMover();
  thingMover.start();
  noStroke();
  noSmooth();
  frameRate(6000);
}

void draw() {
  background(0, 255, 0);
  if (!locked) {
    locked = true;
    thingMover.displayThings();
  }
  locked = false;
}

class Thing {
  float x, y, w, h, speed;
  int id;
  Thing(float x, float y, float w, float h, float speed, int id) {
    this.x = x;   
    this.y = y;   
    this.w = w;
    this.h = h;
    this.speed = speed;
    this.id = id;
  }

  void move() {
    x+=speed;
    if (x <= -thingSize) {
      x = (numThings-1)*thingSize;
    }
  }

  void display() { 
    fill(255);
    rect(x, y, w, h);
    if (id == 0) {
      fill(0);
      text(here, x, y+100);
    }
  }
}

class ThingMover extends Thread {
  Thing[] things = new Thing[numThings];
  boolean running;
  ThingMover() {
    for (int i = 0; i < things.length; i++) {
      things[i] = new Thing(i*thingSize, (height/2)+(i*-2), 64, 400, -1, i);
    }
    running = true;
  }

  public void run() {
    while (running) {
      try {
        sleep(5);
      }
      catch (Exception e) {
        //one day I really will fill this out.
      }
      while (locked);
      locked = true;
      updateThings();
      locked = false;
    }
  }

  void updateThings() {
    for (int i = 0; i < things.length; i++) {
      things[i].move();
    }
  }

  void displayThings() {
    for (int i = 0; i < things.length; i++) {
      things[i].display();
    }
  }
} 