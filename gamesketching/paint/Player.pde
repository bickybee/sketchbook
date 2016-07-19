class Player extends Entity{

	float speed;
	
	Player(int i, StrokeGroup sg, float sp){
		super(i, sg);
		speed = sp;
	}

	void keyPressed(){
		if (key==CODED){
			if (keyCode == UP) this.translate(0,-speed);
			else if (keyCode == DOWN) this.translate(0,speed);
			else if (keyCode == LEFT) this.translate(-speed,0);
			else if (keyCode == RIGHT) this.translate(speed,0);
			reDraw();
		}
	}

}