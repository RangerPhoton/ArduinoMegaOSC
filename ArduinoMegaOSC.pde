/**
 Arduino 
 
 Based on Processing Arduino to OSC example sketch written by Liam Lacey (http://liamtmlacey.tumblr.com)
 Graphics adapted from arduino_input_mega example sketch in Arduino  
 
 This processing sketch allows communication to and from the Arduino (using the processing arduino library), 
 and then converts the data into/from OSC (using the oscP5 library) to communicate to/from other OSC compatible software/hardware, e.g. Max/MSP.
 
 Graphical elements show pin activity in real-time, plus in a treveling graph adapted from code by twitter.com/CedricKiefer 
 
 * In order for this sketch to communicate with the Arduino board, the StandardFirmata Arduino sketch must be uploaded onto the board
 (Examples > Firmata > StandardFirmata)
 
 * OSC code adapted from 'oscP5sendreceive' by andreas schlegel
 * Arduino code taken from the tutorial at http://www.arduino.cc/playground/Interfacing/Processing
 
 
 */


//libraries needed for arduino communication
import processing.serial.*;
import cc.arduino.*;

//libraries needed for osc
import oscP5.*;
import netP5.*;

//variables needed for arduino communication
Arduino arduino;

//variables needed for osc
OscP5 oscP5;
NetAddress myRemoteLocation;

//set/change port numbers here
int incomingPort = 12000;
int outgoingPort = 12001;

//set/change the IP address that the OSC data is being sent to
//127.0.0.1 is the local address (for sending osc to an application on the same computer)
String ipAddress = "127.0.0.1";

boolean Ain = true;
int FirstAin = 0;
int LastAin = 7;  //Arduino Mega: <=15

boolean Din = true;
int FirstDin = 22;
int LastDin = 45;  //Arduino Mega: <=53

boolean Dout = true;
int FirstDout = 2;
int LastDout = 13;  //Arduino Mega: <=53
float[] DoutVal = new float[53];

int DigitalOutPin;
int DigitalOutVal = 0;

color off = color(4, 79, 111);
color on = color(84, 145, 158);
color blank = color(6, 90, 120);
color blankline = color(10, 110, 140);
color label = color(100, 165, 178);



//---------------setup code goes in the following function---------------------
void setup() 
{
  size(880, 540);
  frameRate(30);

  //----for Arduino communication----
  arduino = new Arduino(this, "/dev/cu.usbmodem1421", 57600); //creates an Arduino object

  //set digital pins on arduino to input mode or output mode
  if (Din==true) {
    print("Digital Inputs: ");
    for (int i = FirstDin; i <= LastDin; i++)
    {
      arduino.pinMode(i, Arduino.INPUT);
      print(i+" ");
    }
    println(" ");
    //arduino.pinMode(2, Arduino.INPUT);
    //arduino.pinMode(4, Arduino.INPUT);
    //arduino.pinMode(7, Arduino.INPUT);
    //digital pins are set to output by default, so only the rest of the pins don't need to be manually set to OUTPUT
  }
  if (Ain==true) {
    print("Analog Inputs: ");
    for (int i = FirstAin; i <= LastAin; i++)
      print(i+" ");
    println(" ");
  }

  /* start oscP5, listening for incoming messages at port ##### */
  //for INCOMING osc messages (e.g. from Max/MSP)
  oscP5 = new OscP5(this, incomingPort); //port number set above

  /* myRemoteLocation is a NetAddress. a NetAddress takes 2 parameters,
   * an ip address and a port number. myRemoteLocation is used as parameter in
   * oscP5.send() when sending osc packets to another computer, device, 
   * application. usage see below. 
   */
  //for OUTGOING osc messages (to another device/application)
  myRemoteLocation = new NetAddress(ipAddress, outgoingPort); //ip address set above
}



int xPos = 1;

//----------the following function runs continuously as the app is open------------
//In here you should enter the code that reads any arduino pin data, and sends the data out as OSC
void draw() {
  background(off);

  noFill();
  textSize(12);
  textAlign(CENTER, CENTER);

  int i;

  //read data from all the analog pins and send them out as osc data
  //draw pin diagrams and input data indicators
  for (i = 0; i <= 15; i++)
  {
    if (FirstAin<=i && i<=LastAin && Ain==true) {
      int analogInputData = arduino.analogRead(i); //analog pin i is read and put into the analogInputData variable
      OscMessage analogInputMessage = new OscMessage("/arduino/analog/"+i); //an OSC message in created in the form 'analog/i'
      analogInputMessage.add(map(analogInputData, 0, 1023, 0, 1)); //the analog data from pin i is added to the osc message
      oscP5.send(analogInputMessage, myRemoteLocation); //the OSC message is sent to the set outgoing port and IP address
      stroke(on);
      fill(on);
      ellipse(50 + i * 44, 500, (arduino.analogRead(i) / 30)+2, (arduino.analogRead(i) / 30)+2);
      //print (i+" ");
      inByte[i] = map(analogInputData, 0, 1023, 0, 1);
    } else {
      stroke(blankline);
      fill(blank);
      ellipse(50 + i * 44, 500, 8, 8);
    }
    fill(label);
    text(i, 51 + i * 44, 468);
  }

  //read data from the digital input pins and send them out as osc data
  //draw pin diagrams and input/output data indicators 

  for (i = 0; i <= 53; i++)
  {
    if (Din==true) // i == 2 || i == 4 || i == 7)
    { 
      if (FirstDin<=i && i<=LastDin)
      {
        int digitalInputData = arduino.digitalRead(i); //digital pin i is read and put into the digitalInputData variable
        OscMessage digitalInputMessage = new OscMessage("/arduino/digital/"+i); //an OSC message in created in the form 'digital/i'
        digitalInputMessage.add(digitalInputData); //the digital data from pin i is added to the osc message
        oscP5.send(digitalInputMessage, myRemoteLocation); //the OSC message is sent to the set outgoing port and IP address
        stroke(on);
        if (arduino.digitalRead(i) == Arduino.HIGH)
          fill(on);
        else
          fill(off);
      } else if (FirstDout<=i && i<=LastDout) {
        stroke(color(0, 0, 0));
        float num = map(DoutVal[i], 0, 100, 0, 255);
        fill(color(num, num, num));
      } else {
        stroke(blank);
        fill(blank);
      }

      if (i <= 13) {
        rect(420 - i * 30, 30, 20, 20);
        fill(label);
        text(i, 430 - i * 30, 60);
      } else if (i <= 21) {
        rect(480 + (i - 14) * 30, 30, 20, 20);
        fill(label);
        text(i, 490 + (i - 14) * 30, 60);
      } else {
        rect(780 + (i % 2) * 30, 30 + (i - 22) / 2 * 30, 20, 20);
        fill(label);
        if (i % 2 == 1) text(i, 823 + (i % 2) * 20, 40 + (i - 22) / 2 * 30);
        else text(i, 767 + (i % 2) * 20, 40 + (i - 22) / 2 * 30);
      }
    }
  } 

    //GraphPaper
    //for(int p = 0 ;p<=700/10;p++){
    //stroke(80);
    //line((-frameCount%10)+p*10,150,(-frameCount%10)+p*10,200);

    //line(100,p*10,100,p*10);
    //}
    for (i = 0; i <= LastAin-FirstAin; i++) {
      textSize(11);
      textAlign(LEFT, TOP);
      boolean graph = true;
      if (graph) { 
        // layout two columns of n graphs
        for (i = 0; i <= 15; i++) { 
          int xoffset = 0;
          int yoffset = 0;
          if (i>columnBreak) {
            xoffset = graphWidth+2;
            yoffset = graphHeight*8;
          }
          fill(0);
          stroke(off);
          rect(graphInsetLeft+xoffset, graphInsetTop+(i*graphHeight)-yoffset, graphWidth, graphHeight-2);
          stroke(50);
          line(graphInsetLeft+xoffset, graphInsetTop+(graphHeight/2)+(i*graphHeight)-yoffset, 
            graphInsetLeft+graphWidth+xoffset, graphInsetTop+(graphHeight/2)+(i*graphHeight)-yoffset);
          fill(label);
          text("A"+i, graphInsetLeft+textMargin+xoffset, graphInsetTop+textMargin+(i*graphHeight)-yoffset);
        }
      }

  if (graphs) {
      //Draw moving graphs into a circular buffer
      for (i = FirstAin; i <= LastAin; i++) {
        int xoffset = 0;
        int yoffset = 0;
        if (i>columnBreak) {
          xoffset = graphWidth+2;
          yoffset = graphHeight*8;
        }
        fill(label);
        text(round(inByte[i]*100), graphInsetLeft+textMargin+26+xoffset, graphInsetTop+textMargin+(i*graphHeight)-yoffset);
        noFill();
        stroke(140);
        beginShape();
        for (int p = 0; p<numbers[i].length; p++) {
          vertex(p+graphInsetLeft+xoffset, graphInsetTop+graphHeight-3+(i*graphHeight)-yoffset-numbers[i][p]);
        }
        endShape();
        for (int p = 1; p<numbers[i].length; p++) {
          numbers[i][p-1] = numbers[i][p];
        }
        numbers[i][numbers[i].length-1]=round(inByte[i]*41);
      }
    }
  }
}

//Graphing variables
boolean graphs = true;
int graphWidth = 340;
int graphHeight = 45;
int graphInsetTop = 85;
int graphInsetLeft = 30;
int columnBreak = 7;
int textMargin = 3;
float[] inByte = new float[16]; //array to capture analog input data 
int[][] numbers = new int[16][graphWidth]; //arrays to hold graph pixel data


void mousePressed() {
  if (mouseX<30) graphs = !graphs;
}

//--------incoming osc message are forwarded to the following oscEvent method. Write to the arduino pins here--------
//----------------------------------This method is called for each OSC message recieved------------------------------

boolean debug = false;

void oscEvent(OscMessage theOscMessage) 
{
  // print the address pattern and the typetag of the received OscMessage
  if (debug)
  {
    print("### received an osc message.");
    print(" addrpattern: "+theOscMessage.addrPattern());
    print(" typetag: "+theOscMessage.typetag());
    print(" value: "+theOscMessage.get(0).floatValue() +"\n");
  }
  //-----------------------------------------------------------------------

  int i;
  //sets the incoming value of the OSC message to the oscValue variable
  float oscFloatValue = theOscMessage.get(0).floatValue(); 
  //println(oscFloatValue);  

  //write data to the selected digital output pins (pins 8-13)
  for (i = 8; i <= 13; i++)
  {
    if (theOscMessage.addrPattern().equals("/digital/"+i) == true) //if the osc message = /digital/i/ (i represents the pin number)
    {
      int oscValue = round(abs(oscFloatValue));
      if (oscValue == 0)
      {
        arduino.digitalWrite(i, Arduino.LOW); //turn pin OFF
        if (debug) print("pin turned off\n");
      } else
      {
        arduino.digitalWrite(i, Arduino.HIGH); //turn pin ON
        if (debug) print("pin turned on\n");
      }
      //DigitalOutPin = i;
      DoutVal[i] = oscValue*100;
    }
  }

  //write data to the selected PWM output pins (digital pins 3, 5 and 6 in this example)
  for (i = 3; i <= 7; i++)
  {
    if (theOscMessage.addrPattern().equals("/pwm/"+i) == true) //if the osc message = /pwm/i/ (i represents the pin number)
    {
      int oscValue = round(abs(oscFloatValue)*100);
      arduino.analogWrite(i, oscValue); //sets the pin to the incoming osc data
      //DigitalOutPin = i;
      DoutVal[i] = oscValue;
      if (debug) println("pin "+i+" set to "+oscValue);
    }
  }
}