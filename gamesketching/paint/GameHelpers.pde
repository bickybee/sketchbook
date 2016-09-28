
public void startGame(){
	for (GameObj obj : gameObjs){
		obj.hideUI();

	}
}

public void stopGame(){
	for (GameObj obj: gameObjs){
		obj.revert();
	}
	world.step();

}

public void deleteObj(GameObj obj){
	obj.hideUI();
    gameObjs.remove(obj);
    reDraw();
}