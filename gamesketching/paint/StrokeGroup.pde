import java.util.*;
import fisica.*;

class StrokeGroup{

	ArrayList<Stroke> members;
	float top, bottom, left, right;
	boolean selected;
	boolean belongsToEntity;
	int size;

	StrokeGroup(){
		members = new ArrayList<Stroke>();
		selected = true;
		belongsToEntity = false;
		top = Float.MAX_VALUE;
        bottom = 0;
        left = Float.MAX_VALUE;
        right = 0;
        size = 0;

	}

	void addMember(Stroke s){
		members.add(s);
		size++;
		if (s.left < left) left = s.left;
        if (s.right > right) right = s.right;
        if (s.top < top) top = s.top;
        if (s.bottom > bottom) bottom = s.bottom;
	}

	void removeMember(Stroke stroke){
		members.remove(stroke);
		size--;
		//recalculate bounding box
		update();
	}

	//recalculate key points & bounding box
	void update(){
		top = Float.MAX_VALUE;
        bottom = 0;
        left = Float.MAX_VALUE;
        right = 0;
		for (Stroke s: members){
			if (s.left < left) left = s.left;
	        if (s.right > right) right = s.right;
	        if (s.top < top) top = s.top;
	        if (s.bottom > bottom) bottom = s.bottom;
		}
	}

	boolean boundsContain(float x, float y){
        if (x > left && x < right && y > top && y < bottom) return true;
        else return false;
    }

    void draw(){
    	for (Stroke s: members){
    		s.draw();
    	}
    	if (belongsToEntity) drawBounds(color(50,50,255));
    }

    void drawBounds(color c){
        stroke(c);
        strokeWeight(10);
        drawBox(left, top, right, bottom);
    }

    void translate(float xOff, float yOff){
    	left += xOff;
    	right += xOff;
    	top += yOff;
    	bottom += yOff;
    	for (int i = 0; i < members.size(); i++){
    		members.get(i).translate(xOff, yOff);
		}
    }

	 StrokeGroup copy(){
	 	StrokeGroup copy = new StrokeGroup();
	 	for (Stroke s: members){
	 		copy.members.add(s);
	 	}
	 	copy.selected = selected;
		copy.top = top;
        copy.bottom = bottom;
        copy.left = left;
        copy.right = right;
        copy.size = size;

        return copy;
	 }

	 void createRaster(PGraphics raster, PVector pos, float padding){
	 	for (Stroke s: members){
      		s.draw(raster, pos, padding/2);
    	}
	 }


// --------------------------------------
// GETTERS AND SETTERS
// --------------------------------------

	public ArrayList<Stroke> getMembers() {
		return members;
	}

	public int getSize(){
		return size;
	}

	public void setMembers(ArrayList<Stroke> members) {
		this.members = members;
	}

	public float getTop() {
		return top;
	}

	public void setTop(float top) {
		this.top = top;
	}

	public float getBottom() {
		return bottom;
	}

	public void setBottom(float bottom) {
		this.bottom = bottom;
	}

	public float getLeft() {
		return left;
	}

	public void setLeft(float left) {
		this.left = left;
	}

	public float getRight() {
		return right;
	}

	public void setRight(float right) {
		this.right = right;
	}

	public boolean isSelected() {
		return selected;
	}

	public void setSelected(boolean selected) {
		this.selected = selected;
	}

	public void belongsToEntity(){
		belongsToEntity = true;
	}

	public void removeFromEntity(){
		belongsToEntity = false;
	}

}
