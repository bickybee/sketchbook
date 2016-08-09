public class CodedKeyPublisher extends KeyPublisher{

	KeyEvent codedKey;

	AsciiKeyPublisher(KeyEvent k){
		super();
		codedKey = k;
	}

	private void notifySubcribers(){
		for (GameObj obj : subscribers){
			obj.notify(isPushed, codedKey);
		}
	}
}