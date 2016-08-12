public class SimpleMovement extends Behaviour{

	PVector velocity;
	FBody parentBody;

	SimpleMovement(GameObj o, PVector v){
		super(o);
		velocity = v;
		parentBody = parent.getBody();
	}

	public void update(boolean state){
		if (state) parentBody.setVelocity(velocity.x, velocity.y);
		else parentBody.setVelocity(0, 0);
	}

}