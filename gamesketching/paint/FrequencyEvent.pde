public class FrequencyEvent extends Event{
	
	float frequency; //in seconds
	//-1 means random 
	//0 means ongoing
	//any other number is actually a frequency

	FrequencyEvent(float f){
		super();
		frequency = f;
	}

	public float getFrequency(){
		return frequency;
	}

}