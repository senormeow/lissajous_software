#include <NewSoftSerial.h>
#include <avr/sleep.h>
#include <avr/power.h>

//pin addresses
#define XBEE_DISABLE 8
#define XBEE_TX 6
#define XBEE_RX 7

//Sleep Mode Enables
//#define SLEEP

NewSoftSerial mySerial(6,7);

/* network addresses */
char localhost; //Localhost is pulled from xbee
char gateway = 0;

/* function declarations */
void send_data(char,char);

//Packet Data 
unsigned int analog_data[5];
char set_data[10];

//packet contents
char to;
char from;
char type;

//Timeout
unsigned long timeout;
int send_period = 30000;

char i;
char c; //character to read from serial buffer

void setup() 
{
    //initialize serial communications at 9600 bps:
    Serial.begin(9600); 
    mySerial.begin(9600);
  
    Serial.print("Booting...\n");
    
    //setup pinmodes
    pinMode(2, OUTPUT);
    pinMode(3, OUTPUT);
    pinMode(4, OUTPUT);
    pinMode(5, OUTPUT);
    pinMode(8, OUTPUT);
    pinMode(9, OUTPUT);
    pinMode(10, OUTPUT);
    pinMode(11, OUTPUT);
    pinMode(12, OUTPUT);
    pinMode(13, OUTPUT);

    //flash the output LED on boot
    analogWrite(9,128);
    analogWrite(10,128);
    analogWrite(11,128);
    delay(1000);
    analogWrite(9,0);
    analogWrite(10,0);
    analogWrite(11,0);
    
    Serial.print("Initializing XBee");    
    
    //setup the Xbee
    mySerial.print("+++");
    
    wait_for_ok();
    
    //set up pin sleep
#ifdef SLEEP
    Serial.print("Setting pin sleep\n");
    mySerial.print("ATSM1\r");
    wait_for_ok();
    //verify pin sleep
    Serial.print("Pin sleep set\n");
    mySerial.print("ATSM\r");
    
    Serial.print("ATSM: ");
    echo_softserial(1);
    
#endif   
    
    Serial.print("\r\n");
    //check mote ID
    mySerial.print("ATMY\r");
    
    Serial.print("ATMY: ");
      localhost = echo_softserial(1) - 48;
    Serial.print("\r\n");
    
    Serial.print("Localhost: ");
    Serial.print((int) localhost);
    Serial.print("\r\n");

    Serial.print("Gateway: ");
    Serial.print((int) gateway);
    Serial.print("\r\n");
    
    Serial.print("    [  OK  ]\n");
    
    //flash the status LED
    analogWrite(10,255);
    delay(1000);
    analogWrite(10,0);
    
    Serial.print("Boot finished!\n");

}//end setup

void loop() 
{
    //Only send data once every send_period;
    if(millis() > timeout) 
    {
	//read All analog inputs
	for(i=0;i<5;i++)
	    analog_data[i] = analogRead(i);

        //turn on the radio
#ifdef SLEEP
      	digitalWrite(XBEE_DISABLE,LOW);
#endif      
      	delay(100);   
	//Send data
        send_data(gateway,localhost);
	
        //turn off radio to save power
        delay(100);
#ifdef SLEEP
	digitalWrite(XBEE_DISABLE,HIGH);
#endif
	timeout = millis() + send_period;
     }

    //read a packet from the serial port
    if(mySerial.available() > 13)
    {
       if(mySerial.read() == '#')//check for the start packet delimiter
       {
           to = mySerial.read();
           from = mySerial.read();
           type = mySerial.read();
              for(i =0;i<10;i++)
	        set_data[i] = mySerial.read();
          
          delay(5);
          mySerial.flush();

          if(to == localhost && type == 'S')
          {
	    digitalWrite(2,set_data[0]);	    
	    analogWrite(3,set_data[1]);	    
	    digitalWrite(4,set_data[2]);	    
	    analogWrite(5,set_data[3]);	    
	    digitalWrite(8,set_data[4]);	    
	    analogWrite(9,set_data[5]);	    
	    analogWrite(10,set_data[6]);	    
	    analogWrite(11,set_data[7]);	    
	    digitalWrite(12,set_data[8]);	    
	    digitalWrite(13,set_data[9]);	    	    
          }
        }//end packet header seen
    
    //if we've got garbage on the port, flush it out
    else
    {
      mySerial.flush();
    }
  }//end bytes available to read
  
  
}//end loop()


/* function definitions */


void send_data(char mto, char mfrom)
{
  mySerial.print((char) '#');
  mySerial.print((char) mto);
  mySerial.print((char) mfrom);
  mySerial.print((char) 'D');
  for(i=0;i<5;i++) {
    mySerial.print((char) highByte(analog_data[i]));
    mySerial.print((char) lowByte(analog_data[i]));	
  }

}//end send packet

int wait_for_ok()
{
    //wait for "OK" to be received
    while(1)
    {
        //poll the serial port to see if we get "OK"
        if(mySerial.available() >= 2)
        {
            c = (char) mySerial.read();
            if(c == 'O')
            {
                c = (char) mySerial.read();
                if(c == 'K')
                  break;
            }
        }
    }//end OK check loop
    mySerial.flush();
    return 1;
}//end wait_for_ok

char echo_softserial(char n)
{
    //echos characters from softserial port to UART
    char c;
    while(1)
    {
        if(mySerial.available() >= n)
        {
            for(i = 0; i < n; i++)
            {
                c = (char) mySerial.read();
		Serial.print(c);
            }//end character printing
            mySerial.flush();
            return c; //return last char on the buffer
        }//end characters available
    }//end while (waiting for characters)
}//end echo_softserial
