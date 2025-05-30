import java.awt.event.KeyEvent;
import javax.swing.JOptionPane;
import processing.serial.*;
import javax.swing.JFrame;
Serial port = null;
PImage img;
// select and modify the appropriate line for your operating system
// leave as null to use interactive port (press 'p' in the program)
String portname = null;
//String portname = Serial.list()[0]; // Mac OS X
//String portname = "/dev/ttyUSB0"; // Linux
//String portname = "COM6"; // Windows

boolean streaming = false;
float speed = 0.1;
String[] gcode;
int i = 0;

void openSerialPort()
{
  if (portname == null) return;
  if (port != null) port.stop();
  
  port = new Serial(this, portname, 9600);
  
  port.bufferUntil('\n');
}

void selectSerialPort()
{
  JFrame frame = new JFrame();
  String result = (String) JOptionPane.showInputDialog(frame,
    "Select the serial port that corresponds to your Arduino board.",
    "Select serial port",
    JOptionPane.PLAIN_MESSAGE,
    null,
    Serial.list(),
    0);
    
  if (result != null) {
    portname = result;
    openSerialPort();
  }
}

void setup()
{
  size(800, 350);
  openSerialPort();
  img = loadImage("myImage.png");  // <-- Make sure your image is in the data folder!
  openSerialPort();
}

void draw()
{
  background(0);  
  fill(255);
  textSize(16);
  int y = 24, dy = 18;
  text("INSTRUCTIONS", 22, y); y += dy;

  text("p: select serial port", 18, y); y += dy;
  text("Press 1,2 or 3 to set jog amount ", 22, y); y += dy;
  text("1: set speed to 1 mm per step (1,0 mm) per jog", 18, y); y += dy;
  text("2: set speed to 2.5 mm per step (2,5 mil) per jog", 18, y); y += dy;
  text("3: set speed to 5.0 mm per step (5 mm) per jog", 18, y); y += dy;
  text("arrow keys: jog in x-y plane", 18, y); y += dy;
  text("page up & page down: jog in z axis", 18, y); y += dy;
  text("$: display grbl settings", 18, y); y+= dy;
  text("h: go home", 18, y); y += dy;
  text("0: zero machine (set home to the current location)", 18, y); y += dy;
  text("f: stream a g-code file", 18, y); y += dy;
  text("x: stop streaming g-code (this is NOT immediate)", 18, y); y += dy;
  y = height - dy;
  text("current jog speed: " + speed + " mm per step", 18, y); y -= dy;
  text("current serial port: " + portname, 18, y); y -= dy;
  
  // Draw the image on the right side
  int imgX = width - img.width - 20;  // 20 pixels padding from right edge
  int imgY = 20;                      // 20 pixels from top
  image(img, imgX, imgY);
}

void keyPressed()
{
  if (key == '1') speed = 1.0;
  if (key == '2') speed = 2.5;
  if (key == '3') speed = 5.0;
  
  if (!streaming) {
    if (keyCode == LEFT) port.write("G91\nG20\nG00 X-" + speed + " Y0.000 Z0.000\n");
    if (keyCode == RIGHT) port.write("G91\nG20\nG00 X" + speed + " Y0.000 Z0.000\n");
    if (keyCode == UP) port.write("G91\nG20\nG00 X0.000 Y" + speed + " Z0.000\n");
    if (keyCode == DOWN) port.write("G91\nG20\nG00 X0.000 Y-" + speed + " Z0.000\n");
    if (keyCode == KeyEvent.VK_PAGE_UP) port.write("G91\nG20\nG00 X0.000 Y0.000 Z" + speed + "\n");
    if (keyCode == KeyEvent.VK_PAGE_DOWN) port.write("G91\nG20\nG00 X0.000 Y0.000 Z-" + speed + "\n");
    if (key == 'h') port.write("G90\nG20\nG00 X0.000 Y0.000 Z0.000\n");
    if (key == 'v') port.write("$0=75\n$1=74\n$2=75\n");
    //if (key == 'v') port.write("$0=100\n$1=74\n$2=75\n");
    if (key == 's') port.write("$3=10\n");
    if (key == 'e') port.write("$16=1\n");
    if (key == 'd') port.write("$16=0\n");
    if (key == '0') openSerialPort();
    if (key == 'p') selectSerialPort();
    if (key == '$') port.write("$$\n");
  }
  
  if (!streaming && key == 'g') {
    gcode = null; i = 0;
    File file = null; 
    println("Loading file...");
    selectInput("Select a file to process:", "fileSelected", file);
  }
  
  if (key == 'x') streaming = false;
}

void fileSelected(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    gcode = loadStrings(selection.getAbsolutePath());
    if (gcode == null) return;
    streaming = true;
    stream();
  }
}

void stream()
{
  if (!streaming) return;
  
  while (true) {
    if (i == gcode.length) {
      streaming = false;
      return;
    }
    
    if (gcode[i].trim().length() == 0) i++;
    else break;
  }
  
  println(gcode[i]);
  port.write(gcode[i] + '\n');
  i++;
}

void serialEvent(Serial p)
{
  String s = p.readStringUntil('\n');
  println(s.trim());
  
  if (s.trim().startsWith("ok")) stream();
  if (s.trim().startsWith("error")) stream(); // XXX: really?
}
