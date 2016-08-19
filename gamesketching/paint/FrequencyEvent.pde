public class FrequencyEvent extends Event{
	
	int frequency; //in seconds
	//-1 means random
	//0 means ongoing
	//any other number is actually a frequency

	FrequencyEvent(int f){
		super();
		frequency = f;
	}

	public float getFrequency(){
		return frequency;
	}

}