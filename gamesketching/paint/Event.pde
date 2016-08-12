//encompasses all possible events, that may instigate game object bheaviours
abstract public class Event{

	ArrayList<Behaviour> subscribers;
	boolean occuring;

	Event(){
		subscribers = new ArrayList<Behaviour>();
	}

	public void addSubscriber(Behaviour b){
		if (!subscribers.contains(b)){
			subscribers.add(b);
		}
	}

	public void removeSubscriber(Behaviour b){
		subscribers.remove(b);
	}

	public void notifySubscribers(){
		for (Behaviour b: subscribers){
			b.update(occuring);
		}
	}

}