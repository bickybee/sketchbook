void restartGame(){
	for (GameObj obj: gameObjs){
		obj.revert();
	}
	world.step();

}