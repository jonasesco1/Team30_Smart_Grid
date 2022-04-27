// Rotary Encoder Code
// Marissa Petersile & Tim Leung
// BU ECE Team 14, Class of 2015

// Manually included by Energia
// #include Energia.h if necessary

// Define direction register, output register, and select registers
    #define TA_DIR P1DIR
    #define TA_OUT P1OUT
    #define TA_SEL P1SEL

// Define the bit mask (within the port) corresponding to output TA1
    #define TA1_BIT 0x04

// MAIN FUNCTION ---------------------------------------------
int main(){
  
    WDTCTL = WDTPW + WDTHOLD; // Stop/withhold watchdog timer
    BCSCTL1 = CALBC1_16MHZ; // 8MHz calibration for clock
    DCOCTL = CALDCO_16MHZ;
 
//SETUP THE TIMER (ONCE ONLY) ---------------------------------
    TACTL = TACLR; // reset clock
    TACTL = TASSEL_2+ID_0; // clock source = SMCLK
    // clock divider = 8
    // (clock still off)
    TACCTL0=0; // Nothing on CCR0
    TACCTL1=OUTMOD_7; // reset/set mode
    TACCR0 = 850; // period-1 in CCR0 //18.7kHz
    TACCR1 = 570; // duty cycle in CCR1, change this during loop
    TA_SEL|=TA1_BIT; // connect timer 1 output to pin 2
    TA_DIR|=TA1_BIT;
    TACTL |= MC_1; // timer on in up mode

// DECLARE VARIABLES AND CONSTANTS -----------------------------
    // Measurement Variables
    double diff;
    unsigned long pulseHI;
    long int perIN;
    int duty;
    double perALT;
    
    // Button 1: Each Press makes +0.2Hz
    const int buttonPin1 = 7;
    int buttonState1 = 0;
    pinMode(buttonPin1, INPUT);
    int counterButton1 = 0;
    int dbval1 = 1;
    int debounce1 = true;
    double checkPER;
    
    //Button 2: Each Press makes -0.2Hz
    const int buttonPin2 = 15;
    int buttonState2 = 0;
    pinMode(buttonPin2, INPUT);
    int counterButton2 = 0;
    int dbval2 = 1;
    int debounce2 = true;

    // Fixed values and initialize clock
    int dutyCNG = 1;
    unsigned int counter = 1;
    duty = 570; // 67% duty cycle makes 60Hz
    double perDES = 16666.666; // in us
    int wait = 5000000; // wait 5s before giving up on signal

      

// SAMPLING LOOP: DUTY CYCLE ADAPTER ----------------------------
    while(true)
    {
       counter++;
    
       if (counter % 20000 == 0)
       {
           // Measure period of input signal (us)
           pulseHI = pulseIn(P1_4, HIGH, wait);
           perIN = 2*pulseHI;
           
           
      //Check if Button 1 is being pressed (-0.2Hz)
      buttonState1 = digitalRead(buttonPin1);
      if (buttonState1 == HIGH)
        {
          // Debounce the reading to ensure each HIGH is one button press
          if (debounce1)
            {
              counterButton1++;
              if (counterButton1 >= dbval1)
                {   
                  debounce1 = false;
                  
                  // Make sure new perDES is between 50Hz and 70Hz
                  checkPER = perDES + 55.4;
                  if (checkPER >= 20000)
                      perDES = 20000; // min at 50 Hz
                  else
                      perDES += 55.4; // Equivalent to 0.2Hz change
                }
            }
            
          else
            {
              counterButton1 = 0;
            }
        }
    
      // If not in debounce mode, reset conditions  
      else 
        {
          counterButton1 = 0;
          debounce1 = true;
        }
        

      //Check if Button 2 is being pressed (+0.2Hz)
      buttonState2 = digitalRead(buttonPin2);
      if (buttonState2 == HIGH)
        {
          if (debounce2)
            {
              counterButton2++;
              if (counterButton2 >= dbval2)
                {   
                  debounce2 = false;
                      
                  // Make sure new perDES is between 50Hz and 70Hz
                  checkPER = perDES - 55.4;
                  if (checkPER <= 14286)
                      perDES = 14286; // max at 70Hz
                  else
                      perDES -= 55.4; // Equivalent to 0.2Hz change
                }
            }
          else
            {
              counterButton2 = 0;
            }
        }
      
      // If not in debounce mode, reset conditions 
      else 
        {
          counterButton2=0;
          debounce2 = true;
        }
        
           // Adapt from encoder frequency to alternator frequency
           perALT = perIN*27.63; // constant known from measurement
           
           // Calculate deviation from 60Hz
           diff = perALT - perDES; // change in period in us
              
           // CASE 1: freqIN = freqDES or is very close 
           if (abs(diff) == 0) 
           {
             // Do nothing
           }
  
  
           // CASE 2: freqIN > freqDES; need duty cycle to decrease
           else if (diff < 0)
           {
  
               // Small Change
               if (abs(diff) <= 800)
               {
                  duty -= dutyCNG*10;
               } 
         
               // Medium Change
               else if (abs(diff) <= 1000)
               {
                  duty -= dutyCNG*20;
               } 
           
               // Large Change
               else if (abs(diff) <= 1500)
               {
                  duty -= dutyCNG*30;
               } 
               
               // Max Change
               else
               {
                  duty -= dutyCNG*50;
               }  
            } 
  
            // CASE 3: freqIN < freqDES, need duty cycle to increase
            else if (diff > 0)
            {

               // Small Change
               if (diff <= 800)
               {
                  duty += dutyCNG*10;
               } 
             
               // Medium Change
               else if (diff <= 1000)
               {
                  duty += dutyCNG*20;
               } 
               
               // Large Change
               else if (diff <= 1500)
               {
                  duty += dutyCNG*30;
               } 
               
               // Max Change
               else
               {
                  duty += dutyCNG*50;
               } 
              
             }
  
  // Keep duty cycle from saturating or becoming DC
  if (duty >= 850)
  {
      duty = 850;
  }
  
  else if (duty <= 1)
  {
      duty = 1;
  }
  
  
  // Update duty cycle on output signal
  TACCR1 = duty;
  
  // Reset clock
  counter = 1;
 
    } // end timer-based loop
  
    } // end always-true loop

  
  // Stop CPU and enable interrupts (never occurs if progream does not break)
  __bis_SR_register(GIE+LPM0_bits);

 
  return 0;
}
