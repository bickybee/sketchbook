class Player extends Entity{

	float speed;
	
	Player(int i, StrokeGroup sg, float sp){
		super(i, sg);
		speed = sp;
	}

	void keyHandler(boolean up, boolean down, boolean left, boolean right){
		if (up) this.translate(0,-speed);
		else if (down) this.translate(0,speed);
		else if (left) this.translate(-speed,0);
		else if (right) this.translate(speed,0);
	}


}