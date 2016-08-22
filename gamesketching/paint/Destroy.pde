public class Destroy extends Behaviour{
	
	String bodyName;
	FWorld world;
	boolean destroyAllInstances;

	Destroy(GameObj obj, FWorld w, boolean all){
		super(obj);
		world = w;
		bodyName = Integer.toString(obj.getID());
		destroyAllInstances = all;
	}

	//destroy all instances of body by default
	//else destroy just the instance involved in a collision
	//(hacky?)
	public void update(boolean state){
		if (activated&&state){
			if (destroyAllInstances){
				for (FBody b : gameObj.getBodies()){
					world.remove(b);
				}
				gameObj.resetBodies();
			}
			else{
				FBody removeMe = currentContact.getBody1().getName().equals(bodyName) ?
								currentContact.getBody1() : currentContact.getBody2();
				world.remove(removeMe);
				gameObj.getBodies().remove(removeMe);
			}
		}
	}

	public GameObj getGameObj(){
		return gameObj;
	}

}