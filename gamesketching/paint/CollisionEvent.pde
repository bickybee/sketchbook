public class CollisionEvent extends Event{
	
	//body names!
	String body1;
	String body2;
	boolean singleBodied; // if only a single body is defined, 

	CollisionEvent(String body){
		body1 = body;
		body2 = null;
		singleBodied = true;
	}

	CollisionEvent(String b1, String b2){
		super();
		body1 = b1;
		body2 = b2;
		singleBodied = false;
	}

	public String getBody1(){
		return body1;
	}

	public String getBody2(){
		return body2;
	}

	public boolean isSingleBodied(){
		return singleBodied;
	}

}