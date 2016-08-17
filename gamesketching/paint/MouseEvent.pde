public class MouseEvent extends Event{
	
	int button;

	MouseEvent(int buttonType){
		super();
		button = buttonType;
	}

	public int getButton(){
		return button;
	}

}