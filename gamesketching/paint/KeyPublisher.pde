//key listener/publisher (where GameObjs are the subscribers)
import java.lang.reflect.*;

public class KeyPublisher{

	ArrayList<GameObj> subscribers;
	boolean isPushed;
	int keyValue;

	KeyPublisher(int val){
		keyValue = val;
		isPushed = false;
		subscribers = new ArrayList<GameObj>();

	}

	public void set(boolean pushed){
			isPushed = pushed;
			notifySubscribers();		
	}

	public void addSubscriber(GameObj obj, String methodName){
		if (!subscribers.contains(obj)){
			try {
				Method method = obj.getClass().getMethod(methodName, boolean.class);
				print(keyValue);
				obj.bindMethodToKey(method, keyValue);
				subscribers.add(obj);
				print("subscribed to "+keyValue+"\n");
			} catch (Exception e) {
				print(e+" from addSubsriber \n");
			}
		}
	}

	public void removeSubscriber(GameObj obj){
		subscribers.remove(obj);
		obj.removeKeyBinding(keyValue);
	}

	private void notifySubscribers(){
		for (GameObj obj : subscribers){
			obj.notify(isPushed, keyValue);
		}
	}

}