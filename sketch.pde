int pitchMatch = 60;
int pitchWin = 62;
int pitchLoose = 64;
int velocity = 200;  // Some velocity

void setup() {
  client = new MQTTClient(this);
  // Conect via Internet
  //client.connect("mqtt://try:try@broker.shiftr.io", "processing");
  
  // Connect To localHost (Use IP Adress of Shiftr Host)
  client.connect("mqtt://try:try@192.168.3.12", "processing");
    
  // MidiBus Setup
  MidiBus.list(); // List all available Midi devices on STDOUT. This will show each device's index and name.

  // Either you can
  //                   Parent In Out
  //                     |    |  |
  //myBus = new MidiBus(this, 0, 1); // Create a new MidiBus using the device index to select the Midi input and output devices respectively.

  // or you can ...
  //                   Parent         In                   Out
  //                     |            |                     |
  //myBus = new MidiBus(this, "IncomingDeviceName", "OutgoingDeviceName"); // Create a new MidiBus using the device names to select the Midi input and output devices respectively.

  // or for testing you could ...
  //                 Parent  In        Out
  //                   |     |          |
  myBus = new MidiBus(this, -1, "Bus 1"); // Create a new MidiBus with no input device and the default Java Sound Synthesizer as the output device.
}

// Neccesary as otherwise no updates will happen
void draw() {}

void keyPressed() {
  client.publish("/hello", "world");
}

// Shiftr Callbacks
void clientConnected() {
  println("client connected");

  // Subscribe to your Topics Here
  // Gyroscope
  client.subscribe("/p11/gyr");
  // Magnetometer
  client.subscribe("/p11/acc");
}

// Here anything happens when a message comes in.

float[] gyrVals = new float[3];
float[] accVals = new float[3];

void messageReceived(String topic, byte[] payload) {
  //println("new message: " + topic + " - " + new String(payload));
  
  // The payload is a "char" array, new String () converts that to one string
  String message = new String(payload);
  
  // The Message are CSV so we can split it with ,
  String[] s = split(message, ','); 
  
  float firstValueOfMessageAsFloat = float(s[0]);
  //println("First Value Of Message: " + firstValueOfMessageAsFloat);
  
  // Handle the gyroscope:  
  if (topic.equals("/p11/gyr")) {  
    // Save the Values
    for (int i = 0; i < 3; i++) {   
      gyrVals[i] = float(s[i]);}
    }
    
     if (topic.equals("/p11/acc")) {  
   for (int i = 0; i < 3; i++) {   
      accVals[i] = float(s[i]);}
      if(historyAcc.size()>25){
     historyAcc.remove(0);
     historyAcc.add(new History(accVals));
    }else{historyAcc.add(new History(accVals));}
    } 
    println(historyAcc.size());
    // Do Something with them
    if(mode==0){setCode(); counterTime=0;}
    if(mode==1&&counterTime>25){actions();}
    if(counterTime<30){counterTime++;}
    
 
  //println("GyrVals: X - " + gyrVals[0] + " Y - " + gyrVals[1] + " Z - " + gyrVals[2] + " MagVals: " +accVals[2]);

}

void connectionLost() {
  println("connection lost");
}

void setCode(){
  if(win){code.add(new Code());}
  else{code.clear(); code.add(new Code());}
  codeIndex=0; win=false;
 for(int i=0;i<code.size();i++){
 if(code.get(i).c==0){
 myBus.sendNoteOn(channel, pitchShake, velocity); // Send a Midi noteOn
  delay(delay);
 myBus.sendNoteOff(channel, pitchShake, velocity); // Send a Midi nodeOff
 }
  if(code.get(i).c==1){
 myBus.sendNoteOn(channel, pitchFall, velocity); // Send a Midi noteOn
  delay(delay);
 myBus.sendNoteOff(channel, pitchFall, velocity); // Send a Midi nodeOff
 }
  if(code.get(i).c==2){
 myBus.sendNoteOn(channel, pitchRotate, velocity); // Send a Midi noteOn
  delay(delay);
 myBus.sendNoteOff(channel, pitchRotate, velocity); // Send a Midi nodeOff
 }
  if(code.get(i).c==3){
 myBus.sendNoteOn(channel, pitchPush, velocity); // Send a Midi noteOn
  delay(delay);
 myBus.sendNoteOff(channel, pitchPush, velocity); // Send a Midi nodeOff
 }
  delay(delay*10);
 }
 myBus.sendNoteOn(channel, pitchMatch, velocity); // Send a Midi noteOn
  delay(delay);
 myBus.sendNoteOff(channel, pitchMatch, velocity); // Send a Midi nodeOff
 delay(delay);
 myBus.sendNoteOn(channel, pitchMatch, velocity); // Send a Midi noteOn
  delay(delay);
 myBus.sendNoteOff(channel, pitchMatch, velocity); // Send a Midi nodeOff
 mode=1;
}

void actions() {

  // Example for creating a midi note:
  
  boolean shake=false;
  boolean fall=false;
  boolean rotate=false;
  boolean push=false;
  // Example for creating a controller change
  //int number = 20;     // CC 20
  
  for(int i=0;i<3;i++){                //shake
   if(accVals[i]>15||accVals[i]<-15){
   for(int j=0; j<3;j++){
    if(gyrVals[j]>200){shake=true;} }
   }}
   int counter=0;
  for(int i=0;i<3;i++){               //fall
   if(accVals[i]>14||accVals[i]<-14){
    if(counter==0){fall=true; counter++;}else{fall=false;}
    for(int j=0;j<3;j++){
     if(gyrVals[j]>40||gyrVals[j]<-40){fall=false;}}
   }}
   counter=0;
   boolean rot=false;
   for(int i=0;i<3;i++){            //rotate
    if(accVals[i]<1&&accVals[i]>-1){
     if((gyrVals[i]>100&&gyrVals[i]<180)||(gyrVals[i]<-100&&gyrVals[i]>-180)){
       counter++;
     }}
     if(accVals[i]>9){
     for(int j=0;j<historyAcc.size();j++){
       if(historyAcc.get(j).Vals[i]<-9){rot=true;}
     }}
     if(accVals[i]<-9){
     for(int j=0;j<historyAcc.size();j++){
       if(historyAcc.get(j).Vals[i]>9){rot=true;}
     }
     }
     if(counter==1&&rot){rotate=true;}else{rotate=false;}
   }
   counter=0;  
   boolean pu=false;//push
   for(int i=0;i<3;i++){
    if(accVals[i]>1.5&&accVals[i]<3){
      for(int j=0;j<3;j++){
       if((accVals[j]>9.5&&accVals[j]<10)||(accVals[j]<-9.5&&accVals[j]>-10)){counter++;
       int count2=0;
        for(int l=0;l<historyAcc.size();l++){if(historyAcc.get(l).Vals[i]>1.5&&historyAcc.get(l).Vals[i]<3){count2++;}if(count2>2){pu=true;}}     
       }
      }
    }
    if(accVals[i]<-1.5&&accVals[i]>-3){
    for(int j=0;j<3;j++){
       if((accVals[j]>9.5&&accVals[j]<10)||(accVals[j]<-9.5&&accVals[j]>-10)){counter++;
         int count2=0;
        for(int l=0;l<historyAcc.size();l++){if(historyAcc.get(l).Vals[i]<-1.5&&historyAcc.get(l).Vals[i]>-3){count2++;} if(count2>2){pu=true;}}     
       }
      }
    }
    
    if(counter==1&&pu){push=true;
    for(int y=0;y<3;y++){
      if(gyrVals[i]>30||gyrVals[i]<-30){push=false;}}
    }else{push=false;}
   }
  
  if(shake){
  myBus.sendNoteOn(channel, pitchShake, velocity); // Send a Midi noteOn
  delay(delay);
  myBus.sendNoteOff(channel, pitchShake, velocity); // Send a Midi nodeOff
  
  if(code.get(codeIndex).c==0){
   myBus.sendNoteOn(channel, pitchMatch, velocity); // Send a Midi noteOn
  delay(delay*2);
  myBus.sendNoteOff(channel, pitchMatch, velocity); // Send a Midi nodeOff
  delay(10*delay); codeIndex++;
  }else{
   myBus.sendNoteOn(channel, pitchLoose, velocity); // Send a Midi noteOn
  delay(delay*10);
  myBus.sendNoteOff(channel, pitchLoose, velocity); // Send a Midi nodeOff 
  mode=0; win=false;
  delay(10*delay);
  }
  }
  else if(fall){
  myBus.sendNoteOn(channel, pitchFall, velocity); // Send a Midi noteOn
  delay(delay);
  myBus.sendNoteOff(channel, pitchFall, velocity); // Send a Midi nodeOff
  
  if(code.get(codeIndex).c==1){
   myBus.sendNoteOn(channel, pitchMatch, velocity); // Send a Midi noteOn
  delay(delay*2);
  myBus.sendNoteOff(channel, pitchMatch, velocity); // Send a Midi nodeOff
  delay(10*delay); codeIndex++;
  }else{
   myBus.sendNoteOn(channel, pitchLoose, velocity); // Send a Midi noteOn
  delay(delay*10);
  myBus.sendNoteOff(channel, pitchLoose, velocity); // Send a Midi nodeOff 
  mode=0; win=false;
  delay(10*delay);
  }
  }
  else if(rotate){
  myBus.sendNoteOn(channel, pitchRotate, velocity); // Send a Midi noteOn
  delay(delay);
  myBus.sendNoteOff(channel, pitchRotate, velocity); // Send a Midi nodeOff
  
  if(code.get(codeIndex).c==2){
  myBus.sendNoteOn(channel, pitchMatch, velocity); // Send a Midi noteOn
  delay(delay*2);
  myBus.sendNoteOff(channel, pitchMatch, velocity); // Send a Midi nodeOff
  delay(10*delay); codeIndex++;
  }else{
   myBus.sendNoteOn(channel, pitchLoose, velocity); // Send a Midi noteOn
  delay(delay*10);
  myBus.sendNoteOff(channel, pitchLoose, velocity); // Send a Midi nodeOff 
  mode=0; win=false;
  delay(10*delay);
  }
  }
  else if(push){
  myBus.sendNoteOn(channel, pitchPush, velocity); // Send a Midi noteOn
  delay(delay);
  myBus.sendNoteOff(channel, pitchPush, velocity); // Send a Midi nodeOff
  
  if(code.get(codeIndex).c==3){
  myBus.sendNoteOn(channel, pitchMatch, velocity); // Send a Midi noteOn
  delay(delay*2);
  myBus.sendNoteOff(channel, pitchMatch, velocity); // Send a Midi nodeOff
  delay(10*delay); codeIndex++;
  }else{
   myBus.sendNoteOn(channel, pitchLoose, velocity); // Send a Midi noteOn
  delay(delay*10);
  myBus.sendNoteOff(channel, pitchLoose, velocity); // Send a Midi nodeOff 
  mode=0; win=false;
  delay(10*delay);
  }
  }
  
  if(codeIndex>code.size()-1){
  myBus.sendNoteOn(channel, pitchWin, velocity); // Send a Midi noteOn
  delay(delay*25);
  myBus.sendNoteOff(channel, pitchWin, velocity); // Send a Midi nodeOff 
  mode=0; win=true;
  delay(delay*10);
  }
  // Clamp the value to a range between 0 and 127
  //int value = (int)clamp(gyrVals[0]*0.5,0.0,127.0);
 // myBus.sendControllerChange(channel, number, value); // Send a controllerChange
}



// Clamp values between min and max
public static float clamp(float val, float min, float max) {
    return Math.max(min, Math.min(max, val));
}
