public class AsciiKeyPublisher extends KeyPublisher{

	int asciiCode;

	AsciiKeyPublisher(int ascii){
		super();
		asciiCode = ascii;
	}

	private void notifySubcribers(){
		for (GameObj obj : subscribers){
			obj.notify(isPushed, asciiCode);
		}
	}
}