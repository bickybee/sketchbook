
// paint helper functions

//redraw everything
void reDraw(){
    background(bg);
    if (playing) drawAllGameObjs();
    else{
        for (GameObj obj: gameObjs){
            if (!obj.isSelected()) obj.getStrokes().drawBounds(color(135,206,250));
            else obj.getStrokes().drawBounds(color(50,206,135));
        }
        drawAllStrokes();
    }
    drawAllStrokes();
}

//draw points corresponding to current pen location
void draw(ArrayList<Point> points){
    stroke(currentColour);
    strokeWeight(2);
    noFill();
    beginShape();
    curveVertex(points.get(0).getX(), points.get(0).getY());
    for (int i = 0; i < points.size(); i++){
        curveVertex(points.get(i).getX(), points.get(i).getY());
    }
    if (points.size()>1) curveVertex(points.get(points.size()-1).getX(), points.get(points.size()-1).getY());
    endShape();
    // for (int i = 1; i < points.size(); i++){
    //     strokeWeight(points.get(i).weight);
    //     line(points.get(i).getX(), points.get(i).getY(), points.get(i-1).getX(), points.get(i-1).getY());;
    // }
}

//draw all strokes
void drawAllStrokes(){
    for (Stroke selected: selectedStrokes.getMembers()){
        selected.drawSelected();
    }
    for (Stroke stroke: canvasStrokes.getMembers()){
        stroke.draw();
    }
    if(!playing){
        for (GameObj obj : gameObjs){
            obj.getStrokes().draw();
        }
    }
}

void drawAllGameObjs(){
    for (GameObj obj: gameObjs){
        obj.draw();
    }
}

//draw a box given opposite corners
void drawBox(float x1, float y1, float x2, float y2){
    line(x1,y1,x2,y1);
    line(x2,y1,x2,y2);
    line(x2,y2,x1,y2);
    line(x1,y2,x1,y1);
}

//undo last drawn stroke
void undoStroke(){
    //FIX THIS GROSS LINE
    canvasStrokes.removeMember(canvasStrokes.getMembers().get(canvasStrokes.getSize()-1));
    reDraw();
}

//erase current selection
void eraseSelection(){
    for (Stroke s: selectedStrokes.getMembers()){
        canvasStrokes.removeMember(s); //presumably slow, but it works
    }
    selectedStrokes = new StrokeGroup();
    reDraw();
}

//unselect current selection
void deselectStrokes(){
    for (Stroke s: canvasStrokes.getMembers()){
        if (s.isSelected()) s.deselect();
    }
    selectedStrokes = new StrokeGroup();
}

//for testing
void drawPolygon(Polygon p){
    strokeWeight(5);
    stroke(color(255,0,0));
    Vector2[] vertices = new Vector2[0];
    vertices = p.getVertices();
    for (int i = 1; i < vertices.length; i++){
        line((float)vertices[i-1].x, (float)vertices[i-1].y, (float)vertices[i].x, (float)vertices[i].y);
    }
    line((float)vertices[vertices.length-1].x, (float)vertices[vertices.length-1].y, (float)vertices[0].x, (float)vertices[0].y );
}