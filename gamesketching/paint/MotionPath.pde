public class MotionPath extends Behaviour{

	PVector[] positions;
	int length;
	int currentPos;
	boolean repeatsBackwards;

	MotionPath(GameObj o, PVector[] p, boolean repeat){
		super(o);
		repeatsBackwards = repeat;
		length = p.length;
		positions = new PVector[length];
		for (int i = 0; i < length; i++){
			positions[i] = new PVector(p[i].x, p[i].y);
		}
		currentPos = 0;
	}

	public void update(boolean state){
		for (FBody b : gameObj.getBodies()){
			//should be an OFFSET not an absolute position
		}
	}

}