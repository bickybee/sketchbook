//PEN HANDLERS

void penDown(){

    //ERASE: remove strokes that intersect pen
    if (penMode==Mode.ERASE || (tablet.getPenKind()==Tablet.ERASER && penMode==Mode.DRAW)){       
        for (Stroke stroke: allStrokes){
            if (stroke.intersects(mouseX, mouseY, pmouseX, pmouseY)){
                allStrokes.remove(stroke);
                reDraw();
                break;
            }
        }
    }

    //DRAW: create strokes!
    else if (penMode==Mode.DRAW){

        //just pressed: instantiate new stroke
        if (!penIsDown){
            penIsDown = true;
            currentStroke = new ArrayList<Point>();
            stroke(currentColour);
        }

        if (currentStroke.add(new Point(mouseX, mouseY, 5*tablet.getPressure()))){
            reDraw();
            draw(currentStroke);
        }
        //currentStroke.draw(tablet, mouseX, mouseY, pmouseX, pmouseY);

    }

    //SELECT: select strokes that intersect pen
    //BOX SELECT: create box that will select strokes on penUp
    else if (penMode==Mode.SELECT||penMode==Mode.BOXSELECT){
        
        //if eraser is put down, erase current selection
        if (tablet.getPenKind()==Tablet.ERASER) eraseSelection();

        //translate: move selection along with pen
        else if (translating){
            xOffset = mouseX-pmouseX;
            yOffset = mouseY-pmouseY;
            selectedStrokes.translate(xOffset, yOffset);
            reDraw();
        }

        //just pressed: start new selection
        else if (!penIsDown){
            penIsDown = true;
            deselectStrokes();
            reDraw();
            if (penMode==Mode.BOXSELECT){
                sx1 = mouseX;
                sy1 = mouseY;
            }
        }

        //dragging: check for strokes that intersect and select them
        else if (penMode==Mode.SELECT){
            for (Stroke stroke: allStrokes){
                if (!stroke.isSelected()&&stroke.intersects(mouseX, mouseY, pmouseX,pmouseY)){
                    stroke.select();
                    selectedStrokes.addMember(stroke);
                    reDraw();
                    break;
                }
            }
        }

        //dragging: create box
        else if (penMode==Mode.BOXSELECT){
            sx2 = mouseX;
            sy2 = mouseY;
            reDraw();
            stroke(102);
            drawBox(sx1,sy1,sx2,sy2);
        }
    }

}

void penUp(){

    //DRAW: save finished stroke
    if (penMode==Mode.DRAW){
       Stroke finishedStroke = new Stroke(currentColour, currentStroke);
        allStrokes.add(finishedStroke); //add stroke
        reDraw();
    }

    //BOXSELECT: select all strokes whose **BBs** fall within created box
    //(should change this later to be more precise than BBs)
    if (penMode==Mode.BOXSELECT){
        for (Stroke s: allStrokes){
            if (!s.isSelected()&&s.boundsIntersectRect(min(sx1,sx2), min(sy1,sy2), max(sx1,sx2), max(sy1,sy2))){
                s.select();
                selectedStrokes.addMember(s);
            }
        }
        reDraw();
    }

    penIsDown = false;

}

void penHover(){

    //SELECT or TRANSLATE: distinguish between modes by checking if pen is within current selection bounds
    //gets real gross in here, ungross it
    if (penMode == Mode.SELECT || penMode == Mode.BOXSELECT){
        if (selectedStrokes.boundsContain(mouseX, mouseY)){
            cursor(CROSS);
            translating = true;
        }
        else if (translating){
            cursor(ARROW);
            translating = false;
        } 
    }
}
