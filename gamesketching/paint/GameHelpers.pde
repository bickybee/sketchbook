void restartGame(){
	for (Entity e: entities){
		e.revert();
	}
	world.step();

}