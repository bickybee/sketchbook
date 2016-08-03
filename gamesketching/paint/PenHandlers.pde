//PEN HANDLERS

void penDown(){

    //ERASE: remove strokes that intersect pen
    if (mode==Mode.ERASE || (tablet.getPenKind()==Tablet.ERASER && mode==Mode.PEN)){       
        for (Stroke stroke: allStrokes){
            if (stroke.intersects(mouseX, mouseY, pmouseX, pmouseY)){
                allStrokes.remove(stroke);
                reDraw();
                break;
            }
        }
    }

    //DRAW: create strokes!
    else if (mode==Mode.PEN){

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
    else if (mode==Mode.SELECT||mode==Mode.BOXSELECT){
        
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
            if (mode==Mode.BOXSELECT){
                sx1 = mouseX;
                sy1 = mouseY;
            }
        }

        //dragging: check for strokes that intersect and select them
        else if (mode==Mode.SELECT){
            if (selectedGameObj==null) selectStrokesFrom(allStrokes);
            else selectStrokesFrom(selectedGameObj.getStrokes().getMembers());
        }

        //dragging: create box
        else if (mode==Mode.BOXSELECT){
            sx2 = mouseX;
            sy2 = mouseY;
            reDraw();
            stroke(102);
            drawBox(sx1,sy1,sx2,sy2);
        }
    }

}

void penUp(){

    //if TAP (regardless of mode)
    // if ((mouseX==pmouseX)&&(mouseY==pmouseY)){
    //     print("tapped \n");
    //     if(selectedGameObj==null){
    //         for (GameObj obj: entities){ // if the tap is within an GameObj's bounding box
    //             if (obj.getStrokes().boundsContain(mouseX, mouseY)){
    //                 print("selected \n");
    //                 selectedGameObj = obj;
    //                 break; 
    //             }
    //         }
    //     }
    //     else if(selectedGameObj!=null){
    //         selectedGameObj = null;
    //         print("deselected \n");
    //     }
    // }

    if (translating){//just finished translating strokes
        if(selectedGameObj!=null) selectedGameObj.updateStrokes();
    }

    //DRAW: save finished stroke
    else if (mode==Mode.PEN){
       Stroke finishedStroke = new Stroke(currentColour, currentStroke);
        allStrokes.add(finishedStroke); //add stroke
        if (selectedGameObj!=null) selectedGameObj.addStroke(finishedStroke);
        reDraw();
    }

    //BOXSELECT: select all strokes whose **BBs** fall within created box
    //(should change this later to be more precise than BBs)
    else if (mode==Mode.BOXSELECT){
        if (selectedGameObj==null) boxSelectFrom(allStrokes);
        else boxSelectFrom(selectedGameObj.getStrokes().getMembers());
        reDraw();
    }

    penIsDown = false;

}

void penHover(){

    //SELECT or TRANSLATE: distinguish between modes by checking if pen is within current selection bounds
    //gets real gross in here, ungross it
    if (mode == Mode.SELECT || mode == Mode.BOXSELECT){
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

void selectStrokesFrom(ArrayList<Stroke> strokes){
    for (Stroke stroke: strokes){
        if (!stroke.isSelected()&&stroke.intersects(mouseX, mouseY, pmouseX,pmouseY)){
            stroke.select();
            selectedStrokes.addMember(stroke);
            reDraw();
            break;
        }
    }
}

void boxSelectFrom(ArrayList<Stroke> strokes){
    for (Stroke s: strokes){
        if (!s.isSelected()&&s.boundsIntersectRect(min(sx1,sx2), min(sy1,sy2), max(sx1,sx2), max(sy1,sy2))){
            s.select();
            selectedStrokes.addMember(s);
        }
    }
}