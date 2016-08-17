abstract public class Event{
	
	ArrayList<Behaviour> subscribers;
	boolean isOccuring;

	Event(){
		isOccuring = false;
		subscribers = new ArrayList<Behaviour>();
	}

	public void set(boolean state){
		if (isOccuring != state){
			isOccuring = state;
			notify();	
		}
	}

	public void add(Behaviour b){
		if (!subscribers.contains(b)){
			subscribers.add(b);
		}
	}

	public void remove(Behaviour b){
		subscribers.remove(b);
	}

	public void notifySubcribers(){
		for (Behaviour b : subscribers){
			b.update(isOccuring);
		}
	}

}