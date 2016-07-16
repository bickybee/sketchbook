/**
 * Synchronizes the color of the GlitchySquares
 */
class GlitchyGroup extends Group<GlitchySquare> {

  GlitchyGroup(World w) {
    super(w);
  }

  public void update() {
    color c = pickColor();
    for (GlitchySquare s : getObjects()) {
      s.setColor(c);
    }
  }

  private color pickColor() {
    return color(int(random(256)), int(random(256)), int(random(256)));
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