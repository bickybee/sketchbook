// paint helper functions


void undoStroke(){
    allStrokes.remove(allStrokes.size()-1);
    reDraw();
}

void drawAllStrokes(){
    selectedStrokes.drawBounds();
    for (Stroke selected: selectedStrokes.getMembers()){
        selected.drawSelected();
    }
    for (Stroke stroke: allStrokes){
        stroke.draw();
    }
}

void clearSelection(){
    for (Stroke s: allStrokes){
        if (s.isSelected()) s.deselect();
    }
    selectedStrokes = new StrokeGroup();
}

void eraseSelection(){
    for (Stroke s: selectedStrokes.getMembers()){
        allStrokes.remove(s); //presumably slow, but it works
    }
    selectedStrokes = new StrokeGroup();
    reDraw();
}

void reDraw(){
    background(bg);
    drawAllStrokes();
}

void draw(ArrayList<Point> points){
    stroke(currentColour);
    //strokeWeight(2);
    // noFill();
    // beginShape();
    // curveVertex(points.get(0).getX(), points.get(0).getY());
    // for (int i = 0; i < points.size(); i++){
    //     curveVertex(points.get(i).getX(), points.get(i).getY());
    // }
    // if (points.size()>1) curveVertex(points.get(points.size()-1).getX(), points.get(points.size()-1).getY());
    // endShape();
    for (int i = 1; i < points.size(); i++){
        strokeWeight(points.get(i).weight);
        line(points.get(i).getX(), points.get(i).getY(), points.get(i-1).getX(), points.get(i-1).getY());;
    }
}
