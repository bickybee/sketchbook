public class Spawn extends Behaviour{

	FWorld world;

	Spawn(GameObj obj, FWorld w){
		super(obj);
		world = w;
	}

	public void update(boolean state){
		if (activated&&state){
			world.add(gameObj.spawnBody());
		}
	}

}