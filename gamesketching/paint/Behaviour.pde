//encompasses all possible game object behaviours
abstract public class Behaviour{

	GameObj gameObj;
	boolean activated;

	Behaviour(GameObj obj){
		gameObj = obj;
	}

	abstract public void update(boolean state);

	public void activate(){
		activated = true;
	}

	public void deactivate(){
		activated = false;
	}

}