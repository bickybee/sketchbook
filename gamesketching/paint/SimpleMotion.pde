public class SimpleMotion extends Behaviour{

	PVector velocity;
	ArrayList<FBody> bodies;

	SimpleMotion(GameObj o, PVector v){
		super(o);
		velocity = v;
		bodies = gameObj.getBodies();
	}

	public void update(boolean state){
		if (state){
			for (FBody b : bodies){
				b.setVelocity(velocity.x==0 ? b.getVelocityX() : velocity.x,
							velocity.y==0 ? b.getVelocityY() : velocity.y);
			}
		}
		else{
			for (FBody b : bodies){
				b.setVelocity(0, 0);
			}
		}
	}

}