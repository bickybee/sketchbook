//encompasses all possible game object behaviours
abstract public class Behaviour{

	GameObj gameObj;
	boolean activated;

	Behaviour(GameObj obj){
		gameObj = obj;
		activated = true;
	}

	abstract public void update(boolean state);

	public void activate(){
		activated = true;
	}

	public void deactivate(){
		activated = false;
	}

	public GameObj getGameObj(){
		return gameObj;
	}

}