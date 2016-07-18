class Player extends Entity{

	static final float SPEED = 10;
	
	Player(int i, StrokeGroup sg){
		super(i, sg);
	}

	void keyPressed(){
		print("keypressed \n");
		if (key==CODED){
			if (keyCode == UP) this.translate(0,-SPEED);
			else if (keyCode == DOWN) this.translate(0,SPEED);
			else if (keyCode == LEFT) this.translate(-SPEED,0);
			else if (keyCode == RIGHT) this.translate(SPEED,0);
			reDraw();
		}
	}

}