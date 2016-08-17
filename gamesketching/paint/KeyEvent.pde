public class KeyEvent extends Event{

	int keyValue;

	KeyEvent(int val){
		super();
		keyValue = val;
	}

	public int getKey(){
		return keyValue;
	}

}