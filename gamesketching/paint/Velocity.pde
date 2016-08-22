public class Velocity extends Behaviour{

	PVector velocity;

	Velocity(GameObj o, PVector v){
		super(o);
		velocity = v;
	}

	public void update(boolean state){
		if (state){
			for (FBody b : gameObj.getBodies()){
				b.setVelocity(velocity.x==0 ? b.getVelocityX() : velocity.x,
				velocity.y==0 ? b.getVelocityY() : velocity.y);
			}
		}
		else{
			for (FBody b : gameObj.getBodies()){
				b.setVelocity(0, 0);
			}
		}
	}

}