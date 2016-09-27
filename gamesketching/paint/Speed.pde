public class Speed extends Behaviour{

	float speed;
	PVector defaultDirection;

	Speed(GameObj o, float s, PVector d){
		super(o);
		speed = s;
		defaultDirection = d;
	}

	public void update(boolean state){
		if (state){
			PVector direction;
			for (FBody b : gameObj.getBodies()){
				if ((b.getVelocityX()==0)&&b.getVelocityY()==0) direction = defaultDirection;
				else direction = new PVector(b.getVelocityX(), b.getVelocityY());
				direction.normalize();
				b.setVelocity(speed*direction.x, speed*direction.y);
			}
		}
		else{
			for (FBody b : gameObj.getBodies()){
				b.setVelocity(0, 0);
			}
		}
	}

}