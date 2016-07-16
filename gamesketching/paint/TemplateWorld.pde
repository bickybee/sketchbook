static final int SQUARE_NUM = 10;

class TemplateWorld extends World {
  TemplateWorld(int portIn, int portOut) {
    super(portIn, portOut);
  }

  void draw() {
    background(0);
    super.draw();
}

  void setup() {
    //GlitchyGroup g = new GlitchyGroup(this);
    // register(g);
    //     for (int i = 0; i < SQUARE_NUM; i++) {
	   //      g.addSquare();
    // }
    //register(g,g,new SquareInteractor());
    //subscribe(g, POCodes.Key.A);
  }
}
