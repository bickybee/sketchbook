/**
 * you can put a one sentence description of your tool here.
 *
 * (c) 2016
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 * 
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 * 
 * You should have received a copy of the GNU Lesser General
 * Public License along with this library; if not, write to the
 * Free Software Foundation, Inc., 59 Temple Place, Suite 330,
 * Boston, MA  02111-1307  USA
 * 
 * @author		Joel Moniz http://joelmoniz.com
 * @modified	02/15/2016
 * @version		##version##
 */

package jm.shape_sketch.tool;

import processing.app.*;
import processing.app.tools.*;

public class ShapeSketch implements Tool {

	// when creating a tool, the name of the main class which implements Tool
	// must be the same as the value defined for project.name in your
	// build.properties

	public static final String TOOL_NAME = "Shape-Sketch";
	Base bass;

	@Override
	public String getMenuTitle() {
		return TOOL_NAME;
	}

	@Override
	public void init(Base base) {
	  bass = base;
	}

	@Override
	public void run() {
		System.out
				.println(TOOL_NAME + " v0.8.0 by Joel Moniz http://joelmoniz.com");
		GUIFrame.getGUIFrame(bass).setVisible(true);
	}

	public static void main(String[] args) {
		new ShapeSketch().run();
	}

}
