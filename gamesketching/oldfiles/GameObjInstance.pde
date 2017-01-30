public class GameObjInstance {
	
	int id;
	private FBody body;
	private PGraphics sprite;
	private GameObj parent;

	GameObjInstance(int i, FBody b, PGraphics s, GameObj p){
		id = i;
		body = b;
		sprite = s;
		parent = p;
	}

	public void setSprite(PGraphics newSprite){
		sprite = newSprite;
	}

	public PGraphics getSprite(){
		return sprite;
	}

	public FBody getBody(){
		return body;
	}

	public GameObj getParent(){
		return parent;
	}

	public int getID(){
		return id;
	}

	public float getX(){
		return body.getX();
	}

	public float getY(){
		return body.getY();
	}

	public void setPosition(float x, float y){
		body.setPosition(x, y);
	}

	public void setVelocity(float x, float y){
		body.setVelocity(x, y);
	}

	public float getVelocityY(){
		return body.getVelocityY();
	}

	public float getVelocityX(){
		return body.getVelocityX();
	}

}
