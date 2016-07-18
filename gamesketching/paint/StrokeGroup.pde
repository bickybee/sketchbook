import org.dyn4j.*;
import org.dyn4j.geometry.*;
import org.dyn4j.geometry.decompose.*;
import java.util.*;

class StrokeGroup{

	ArrayList<Stroke> members;
	ArrayList<Point> allKeyPoints;
	//ArrayList<Vector2[]> allKeyPoints;
	//List<Polygon> polygons;
	float top, bottom, left, right; //group bounding box
	boolean selected;
	int size;

	StrokeGroup(){
		members = new ArrayList<Stroke>();
		allKeyPoints = new ArrayList<Point>();
		//allKeyPoints = new ArrayList<Vector2>();
		//polygons = new ArrayList<Polygon>();

		selected = true;
		top = Float.MAX_VALUE;
        bottom = 0;
        left = Float.MAX_VALUE;
        right = 0;
        size = 0;

	}

	void addMember(Stroke s){
		members.add(s);
		size += s.keyPoints.length;
		Collections.addAll(allKeyPoints, s.keyPoints);
		if (s.left < left) left = s.left;
        if (s.right > right) right = s.right;
        if (s.top < top) top = s.top;
        if (s.bottom > bottom) bottom = s.bottom;
	}

	boolean boundsContain(float x, float y){
        if (x > left && x < right && y > top && y < bottom) return true;
        else return false;
    }

    void draw(){
    	for (Stroke s: members){
    		s.draw();
    	}
    }

    void drawBounds(){
        stroke(102);
        strokeWeight(2);
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

     Polygon convexHull(){
	    GiftWrap wrapper = new GiftWrap();
	    Vector2[] inputPoints = new Vector2[size];
	    for (int i = 0; i < size; i++){
	      inputPoints[i] = allKeyPoints.get(i).getVector2();
	    }
	    return new Polygon (wrapper.generate(inputPoints));
	  }

    // void decompose(){
    // 	Vector2[] inputPoints = new Vector2[0];
    // 	inputPoints = allKeyPoints.toArray(inputPoints);
    // 	Bayazit decomposer = new Bayazit();
    // 	List<Convex> convexShapes = new ArrayList<Convex>();
    // 	convexShapes = decomposer.decompose(inputPoints);
    // 	for (Convex shape: convexShapes){
    // 		polygons.add((Polygon)shape);
    // 	}
    // }

// --------------------------------------
// GETTERS AND SETTERS
// --------------------------------------

	public ArrayList<Point> getKeyPoints(){
		return allKeyPoints;
	}

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

}
