#include "enuminclude.h"

//Sampling Rate = 400 Hz
//E_UPDATE should be 25 for Fs = 250 Hz, 40 for Fs = 400 Hz. [update every 0.1 second]
#define E_UPDATE 25
#define WINDOW_SIZE 30

int buttonPin = 2;
int buttonState = 0;
//int buzpin=4;
int bit_0=8;
int bit_1=12;
int bit_2=13;

// to generate square waves for testing
int waveSample = 0, waveEnergy = 0;
volatile int state_id = -1;

float mean_eye[2], threshold_value = 0;
int interruptPin = 2;
int i, j, k, l, m, n;
volatile int energyUpdateCnt = 0;
volatile long sampleCnt = 1; //global Sample counter. Updated every new sample.
volatile long energyCnt = 0; //global Energy counter. Updated after every Energy computation.

//float energy = 0;
int N = 100;

long y, p, bufferValueInsert = 0, bufferValueKicked, energyBuffer[WINDOW_SIZE] = {0};
volatile long sumBuffer = 0, oldSumBuffer = 0;

long x[100], sum[20];

int timer_value = 7999; //250 Hz = 7999, 400 Hz = 4999


long h[101] = {
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, -1, -1,  -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, -1, -1, -1, -1, -1, -1, -1, -1, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};
#ifndef cbi
#define cbi(sfr, bit) (_SFR_BYTE(sfr) &= ~_BV(bit))
#endif
#ifndef sbi
#define sbi(sfr, bit) (_SFR_BYTE(sfr) |= _BV(bit))
#endif

void setup()
{
 Serial.begin(250000);
 pinMode(buttonPin, INPUT_PULLUP);
 pinMode(4,OUTPUT);
 pinMode(12, OUTPUT);
 pinMode(8, OUTPUT);
 pinMode(7, OUTPUT);

  cli();//stop interrupts
  //Make ADC sample faster. Change ADC clock
  //Change prescaler division factor to 16
  sbi(ADCSRA,ADPS2);//1
  cbi(ADCSRA,ADPS1);//0
  cbi(ADCSRA,ADPS0);//0

  //set timer1 interrupt at 1kHz
  TCCR1A = 0;// set entire TCCR1A register to 0
  TCCR1B = 0;// same for TCCR1B
  TCNT1  = 0;//initialize counter value to 0;
  // set timer count for 500 Hz increments
  OCR1A = timer_value;        //= (16*10^6) / (1000*8) - 1 // 
  // turn on CTC mode
  TCCR1B |= (1 << WGM12);
  // Set CS11 bit for 8 prescaler
  TCCR1B |= (1 << CS11);   
  // enable timer compare interrupt
  TIMSK1 |= (1 << OCIE1A);
  
  sei();//allow interrupts


  
}
    
ISR(TIMER1_COMPA_vect)
{
   for(i = N-2; i>=0; i--)
   {
    x[i+1] = x[i];
   }
  
  x[0] = analogRead(A0);
  x[0] = x[0] - 512;
  //x[0] = x[0] * 5 / 1024;
     
  y = 0;
  
  for(k = 0; k<N; k++)
  {
    y = y + x[k]*h[k];
  }

  p = y*y;

  //Sample number, Sample value sent over Serial
  Serial.print(sampleCnt);
  Serial.print(",");
  Serial.print((int)x[0]);
  Serial.print(",");
  Serial.println(state_id);
  sampleCnt++;

  //waveSample = ~waveSample;
  //digitalWrite(8, waveSample);
  
  energyUpdateCnt++;
  bufferValueInsert += p;
    
  
  //energy is updated after W_UPDATE filtered samples
  if(energyUpdateCnt == E_UPDATE)
    {
      bufferValueKicked = energyBuffer[WINDOW_SIZE - 1];
      for(l = WINDOW_SIZE - 2; l >= 0; l--)
      {
        energyBuffer[l+1] = energyBuffer[l];
      }
      energyBuffer[0] = bufferValueInsert;
      oldSumBuffer = sumBuffer;
      sumBuffer = sumBuffer + energyBuffer[0] - bufferValueKicked;
      
      energyCnt++;  //global update
      //waveEnergy = ~waveEnergy;
      //digitalWrite(7, waveEnergy);


      //Serial.println(sumBuffer);
      bufferValueInsert = 0;
      energyUpdateCnt = 0;
    }
  
}

//Calculation for mean during 30 seconds of Eye Open
int start_state(void)
{
  digitalWrite(bit_0,LOW);
  digitalWrite(bit_1,LOW);
  digitalWrite(bit_2,LOW);
  long entryTime = energyCnt;
  state_id = 0;
  //Serial.println("\"START\",");
  while(energyCnt - entryTime < 100)
  {
  }
  return ok;
}

int th_eye_open_state(void)
{
  //buzzer2();
  //buzzer2();
  digitalWrite(bit_0,HIGH);
  digitalWrite(bit_1,LOW);
  digitalWrite(bit_2,LOW);
  int cnt = 1;
  state_id = 1;
  float total_sum = 0, oldSumBuffer;
  //long entryTime = millis();
  long entryEnergyWin = energyCnt;
  long prevEnergyCnt = energyCnt;
  
  //Serial.println("\"EO\",");
  //Serial.print("Started Th Eye Open @ ");
  //Serial.println(entryEnergyWin);
  
  //Serial.println(entryTime);
  //Serial.println(entryTime);
  //while(millis() - entryTime < 30000)
  while(energyCnt - entryEnergyWin  < 300)
  {
    //Serial.println("I'm here");
    if(energyCnt != prevEnergyCnt)
    {
      //waveEnergy = ~waveEnergy;
      //digitalWrite(7, waveEnergy);
      //Serial.println("I'm inside");
      total_sum += sumBuffer;
      cnt++;
      prevEnergyCnt = energyCnt;  
    }
  }
  //Serial.println(energyCnt - entryEnergyWin);
  //Serial.println(millis() - entryTime);
  mean_eye[0] = (float)total_sum / cnt;
  //Serial.print("Count = ");
  //Serial.println(cnt);
  return ok;
}

//Calculation for mean during 30 seconds of Eye Closed
int th_eye_close_state(void)
{
  //buzzer1();
  digitalWrite(bit_0,LOW);
  digitalWrite(bit_1,HIGH);
  digitalWrite(bit_2,LOW);
  int cnt = 1;
  state_id = 2;
  float total_sum = 0, oldSumBuffer;
  long entryEnergyWin = energyCnt;
  long prevEnergyCnt = energyCnt;
  
  //Serial.println("\"EC\",");
  //Serial.print("Started Th Eye Close @ ");
  //Serial.println(entryEnergyWin);
  
  while(energyCnt - entryEnergyWin  < 300)
  {
    if(energyCnt != prevEnergyCnt)
    {
      total_sum += sumBuffer;
      cnt++;
      prevEnergyCnt = energyCnt;  
    }
  }
  //Serial.println(energyCnt - entryEnergyWin);
  mean_eye[1] = (float)total_sum / cnt;
  return ok;
}

//Compute the threshold according to the formula
int threshold_state(void)
{
  //Serial.print("Threshold = ");
  threshold_value = (6*mean_eye[0] + 3*mean_eye[1])/9;
  return ok;
}

int sr_state(void)
{
  //buzzer1();
  digitalWrite(bit_0,HIGH);
  digitalWrite(bit_1,HIGH);
  digitalWrite(bit_2,LOW);
  long entryTime = energyCnt;
  state_id = 3;
  //Serial.println("\"SR\",");
  //Serial.println(entryTime);
  while(energyCnt - entryTime < 150)
  {
    if(digitalRead(buttonPin) == LOW)
    {
      //Serial.println("\"KP\",");
      return ok;
    }
    
    if(oldSumBuffer < threshold_value && sumBuffer >= threshold_value)
    {
      state_id = 4;
       digitalWrite(bit_0,LOW);
      digitalWrite(bit_1,LOW);
      digitalWrite(bit_2,HIGH);
    }
    else
    {
      state_id = 3;
       digitalWrite(bit_0,HIGH);
      digitalWrite(bit_1,HIGH);
      digitalWrite(bit_2,LOW);
    }
  }
  return fail;
}

int ic_state(void)
{
    digitalWrite(bit_0,HIGH);
  digitalWrite(bit_1,LOW);
  digitalWrite(bit_2,HIGH);
  long entryTime = energyCnt;
  //Serial.println("\"IC\",");
  //Serial.println(entryTime);
  state_id = 5;
  while(energyCnt - entryTime < 150)
  {
    //Serial.println(sumBuffer);
    if(oldSumBuffer < threshold_value && sumBuffer >= threshold_value)
       {
          digitalWrite(bit_0,LOW);
          digitalWrite(bit_1,HIGH);
          digitalWrite(bit_2,HIGH);
        //buzzer2();
        //buzzer2();
        //Serial.println("\"AD\",");
        return ok;
       }
  }
  return fail;
}

int wait_state(void)
{
  long entryTime = energyCnt;
  state_id = 6;
  //Serial.println("\"WA\",");
  //Serial.println(entryTime);
  while(energyCnt - entryTime < 50)
  {
  }
  return ok;
}
int over_state(void)
{
  digitalWrite(bit_0,HIGH);
  digitalWrite(bit_1,HIGH);
  digitalWrite(bit_2,HIGH);
  
  long entryTime = energyCnt;
  state_id = 7;
  //Serial.println("\"EXIT\",");
  //Serial.println(entryTime);
  Serial.print("Threshold was ");
  Serial.println(threshold_value);
  Serial.end();
  while(1)
  {
    
  }
  return ok;
}

int (*state[])(void) = {start_state, th_eye_open_state, th_eye_close_state, threshold_state, sr_state, ic_state, wait_state, over_state};

struct transition
{
  enum state_codes src_state;
  enum ret_codes ret_code;
  enum state_codes dst_state;
};

struct transition state_transitions[] = {
  {start, ok, th_eye_open},
  //{th_eye_open, ok, start},
  {th_eye_open, ok, th_eye_close},
  {th_eye_close, ok, threshold},
  {threshold, ok, sr},
  {sr, ok, ic},    //sr -> ic (button press < 15 seconds)
  {sr, fail, over}, //sr -> exit (no button press in 15 seconds)
  {ic, ok, wait},   //ic -> wait for 5 secs after alpha detection
  {ic, fail, sr},   //ic -> sr (no alpha detected in 15 seconds)
  {wait, ok, sr},   //wait -> sr
};

enum state_codes lookup_transitions(enum state_codes current, enum ret_codes ret)
{
  int i = 0;
  enum state_codes temp = over;
  for (i = 0;; ++i) {
    if (state_transitions[i].src_state == current && state_transitions[i].ret_code == ret)
    {
      temp = state_transitions[i].dst_state;
      break;
    }
  }
  return temp;
}

#define ENTRY_STATE start
#define EXIT_STATE over

void loop()
{
//  Serial.println(p);
  enum state_codes cur_state = ENTRY_STATE;
  enum ret_codes rc;        //value returned by the state
  int (*state_run)(void);

  for(;;)
  {
    state_run = state[cur_state];
    rc = state_run();
    if(EXIT_STATE == cur_state)
      break;
    cur_state = lookup_transitions(cur_state, rc);
  }
}

