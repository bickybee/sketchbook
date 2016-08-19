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
			notifySubscribers();	
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

	public void remove(GameObj obj){
		GameObj removeMe;
		for (int i = 0; i < subscribers.size(); i++){
			if (subscribers.get(i).getGameObj()==obj){
				subscribers.remove(i);
				break;
			}
		}
	}

	public void notifySubscribers(){
		for (Behaviour b : subscribers){
			b.update(isOccuring);
		}
	}

}