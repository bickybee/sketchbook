import java.util.Timer.*;

public class Animate extends Behaviour{
	
	PGraphics frame;
	PGraphics original;
	float frameLength;

	Animate(GameObj o, PGraphics f, float t){
		super(o);
		frame = f;
		frameLength = t;
		original = gameObj.getRaster();
	}

	public void update(boolean state){
		print("animate \n");
		if (state){
			gameObj.setRaster(frame);

			if (frameLength > 0){
				Timer timer = new Timer();
				timer.schedule(new TimerTask() 
					{
					  @Override
					  public void run() 
					  {
					       gameObj.setRaster(original);
					  }
					}, (long)(frameLength*1000));
			}
		}

		else {
			gameObj.setRaster(original);
		}

	}
}