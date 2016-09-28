//PEN HANDLERS

void penDown(){

    //ERASE: remove strokes that intersect pen
    if (mode==Mode.ERASE || (tablet.getPenKind()==Tablet.ERASER)){    
        if (selectedGameObj==null) eraseFrom(canvasStrokes);
        else eraseFrom(selectedGameObj);   
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
        if (tablet.getPenKind()==Tablet.ERASER){
            eraseSelection();
            reDraw();
        }

        //translate: move selection along with pen
        else if (translating){
            penIsDown = true;
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
            if (selectedGameObj==null) selectStrokesFrom(canvasStrokes);
            else selectStrokesFrom(selectedGameObj);
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
    if (translating&&(selectedGameObj!=null)){
        selectedGameObj.updateStrokes();
        reDraw();
    }

    //DRAW: save finished stroke
    if (mode==Mode.PEN){
       Stroke finishedStroke = new Stroke(currentColour, currentStroke);
        if (selectedGameObj==null) canvasStrokes.addMember(finishedStroke); //add stroke
        else selectedGameObj.addStroke(finishedStroke);
        reDraw();
    }

    //BOXSELECT: select all strokes whose **BBs** fall within created box
    //(should change this later to be more precise than BBs)
    else if (mode==Mode.BOXSELECT){
        if (selectedGameObj==null) boxSelectFrom(canvasStrokes);
        else boxSelectFrom(selectedGameObj);
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

//returns intersected stroke
void eraseFrom(StrokeGroup strokes){
    for (int i = 0; i < strokes.getMembers().size(); i++){
        print ("i: "+i+", size:"+strokes.getMembers().size()+"\n");
        //if erasing line intersects stroke, remove it from list of strokes
        if (strokes.getMembers().get(i).intersects(mouseX, mouseY, pmouseX, pmouseY)){
            //if this stroke is part of the current stroke selection, erase the whole selection
            if (selectedStrokes.getMembers().contains(strokes.getMembers().get(i))) eraseSelection();
            //otherwise just erase that stroke
            else strokes.removeMember(strokes.getMembers().get(i));
            reDraw();
        }
    }
}

void eraseFrom(GameObj obj){
    eraseFrom(obj.getStrokes());
    if (obj.getStrokes().getSize()>0) obj.updateStrokes();
    else { //if there are no more strokes left in the obj, remove it
        obj.hideUI();
        gameObjs.remove(obj);
        selectedGameObj = null;
    }  
}

void selectStrokesFrom(GameObj obj){
    selectStrokesFrom(obj.getStrokes());
    obj.updateStrokes();
}

void selectStrokesFrom(StrokeGroup strokes){
    for (Stroke stroke: strokes.getMembers()){
        if (!stroke.isSelected()&&stroke.intersects(mouseX, mouseY, pmouseX,pmouseY)){
            stroke.select();
            selectedStrokes.addMember(stroke);
            print("selected strokes: "+selectedStrokes.getSize()+"\n");
            reDraw();
            break;
        }
    }
}

void boxSelectFrom(GameObj obj){
    if (boxSelectFrom(obj.getStrokes())) obj.updateStrokes();;
}

boolean boxSelectFrom(StrokeGroup strokes){
    for (Stroke s: strokes.getMembers()){
        if (!s.isSelected()&&s.boundsIntersectRect(min(sx1,sx2), min(sy1,sy2), max(sx1,sx2), max(sy1,sy2))){
            s.select();
            selectedStrokes.addMember(s);
            return true;
        }
    }
    return false;
}

