
public void startGame(){
	for (GameObj obj : gameObjs){
		obj.hideUI();

	}
}

void stopGame(){
	for (GameObj obj: gameObjs){
		obj.revert();
	}
	world.step();

}