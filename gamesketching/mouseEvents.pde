// mouse event stuff that is for some reason more laggy?

// pen down
void mousePressed(){

    //DRAW
    if (penMode==Mode.DRAW){
        currentStroke = new Stroke(currentColour);
        stroke(currentColour);
    }

    //SELECT: on pen-down, start new selection
    else if (penMode==Mode.SELECT){
        for (Stroke s: selectedStrokes.getMembers()) s.deselect();
        selectedStrokes = new StrokeGroup();
        refresh();
    }


}

//pen dragged
void mouseDragged(){

    //DRAW
    if (penMode==Mode.DRAW){
        //add new point to stroke
        Point currentPoint = new Point(mouseX, mouseY, 5*tablet.getPressure());
        currentStroke.addPoint(currentPoint);
        currentStroke.drawStroke(tablet, mouseX, mouseY, pmouseX, pmouseY);
    }


    //ERASE: remove strokes that cross with pen-line
    else if (penMode==Mode.ERASE || tablet.getPenKind()==Tablet.ERASER){       
        for (Stroke stroke: allStrokes){
            if (stroke.intersectsLine(mouseX, mouseY, pmouseX, pmouseY)){
                allStrokes.remove(stroke);
                refresh();
                break;
            }
        }
    }

    //SELECT: select strokes that cross with pen-line
    else if (penMode==Mode.SELECT){
        for (Stroke stroke: allStrokes){
            if (!stroke.isSelected()&&stroke.intersectsLine(mouseX, mouseY, pmouseX, pmouseY)){
                stroke.select();
                selectedStrokes.addMember(stroke);
                refresh();
                break;
            }
        }
    }

    //TRANSLATE: move current selection along with pen
    else if (penMode==Mode.TRANSLATE){
        xOffset = mouseX-pmouseX;
        yOffset = mouseY-pmouseY;
        selectedStrokes.translate(xOffset, yOffset);
        refresh();
        selectedStrokes.drawBounds();
    }


}

//pen up
void mouseReleased(){

    //DRAW: save completed stroke
    if (penMode==Mode.DRAW){
        Stroke finishedStroke = new Stroke(currentColour);
        for (Point p: currentStroke.points){
            finishedStroke.addPoint(new Point(p.getX(), p.getY(), p.getWeight()));
        }
        allStrokes.add(finishedStroke); //add stroke
        print("drawn"+allStrokes.size()+"\n");
    }

}

void mouseMoved(){
    //hover
    if (!mousePressed){ 

        //SELECT and TRANSLATE: determine select or translate mode based on whether cursor is over selection or not
        if (penMode == Mode.SELECT || penMode == Mode.TRANSLATE){
            if (selectedStrokes.hasWithinBounds(mouseX, mouseY)){
                cursor(CROSS);
                penMode = Mode.TRANSLATE;
            }
            else {
                cursor(ARROW);
                penMode = Mode.SELECT;
            }    
        }
    }

}