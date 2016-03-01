//Include all the packages from the minim audio analyzer library
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

/*------------Dots------------------------*/
//Dots array that will hold all of the dots for the entire sketch
Dots[] dots;

//The number of dots that will be created
int numDots;                                                              


/*---------Color scheme constants------------*/
//Will hold the rgb values for the 5 constant purple colors
color purple1, purple2, purple3, purple4, purple5;

//Will hold the rgb values for the 5 constant pink colors
color pink1, pink2, pink3, pink4, pink5;                                  

//All of these values were determined outside of processing
color blue1, blue2, blue3, blue4, blue5;                                  

//Color arrays to sort colors and make accessing them easier
color[] purples, pinks, blues, colors;                                    


/*-------minim audio object declarations--------*/
//The main manager for the minim audio library
Minim minim;                                      

//This will hold all of the information about the song
AudioPlayer player;                                                       

//This specifically holds info such as title, author, runtime, etc
AudioMetaData metaData;                                                   

//This is the Fourier Fast Transform object that will be used for the spectrograph
FFT fft;                                                                  

/*------------Intro-----------*/
//This holds the title that will be displayed in the beginning
String title;                                                              

//The time in millis of the fade in sequence for the intro
float fadeInTime;                                                          

//This keeps track of how blurry the screen should be
float fadeValue;                                                           

//This stores the total time alloted for the intro
float introTime;                                                           

//This PShader object allows for fast Guassian blurring
PShader blur;                                                              

//This will keep track of the time the loading finishes
float introStartTime = -10;                                                

/*-------basic declarations---------*/ 
void setup()
{
  //The horizontal size is very specific as it matches the buffer length
  //for the song. It should only be a power of two.
  size(1024,480,P3D);                                                      
                                                                            
  //set values for the color constants
  //predetermined rgb values are set for the colors
  purple1 = color(173,129,196);                                            
  purple2 = color(136,81,163);
  purple3 = color(111,52,141);
  purple4 = color(90,30,121);
  purple5 = color(68,13,96);
  
  pink1 = color(221,141,185);
  pink2 = color(198,93,151);
  pink3 = color(171,57,119);
  pink4 = color(146,31,94);
  pink5 = color(116,10,68);
  
  blue1 = color(152,135,199);
  blue2 = color(110,89,168);
  blue3 = color(82,59,145);
  blue4 = color(60,37,124);
  blue5 = color(40,19,98);
  
  //The purple array will store the five purple colors
  purples = new color[5];                                                  
  pinks = new color[5];
  blues = new color[5];
  
  //The color array will store all of the colors
  colors = new color[15];                                                  
  
  //adding of the colors to the arrays
  purples[0] = purple1;                                                    
  purples[1] = purple2;
  purples[2] = purple3;
  purples[3] = purple4;
  purples[4] = purple5;
  
  pinks[0] = pink1;
  pinks[1] = pink2;
  pinks[2] = pink3;
  pinks[3] = pink4;
  pinks[4] = pink5;
  
  blues[0] = blue1;
  blues[1] = blue2;
  blues[2] = blue3;
  blues[3] = blue4;
  blues[4] = blue5;
  
  //iterating over the length of each of the indiv. color arrays to add
  //them to the master array. I didn't want an array of arrays.
  //purples take spots 0-4, pink 5-9, blues 10- 14
  for(int i = 0; i < 5; i++)                                              
  {                                                                       
    colors[i] = purples[i];                                               
    colors[i+5] = pinks[i];
    colors[i+10] = blues[i];
  }
  

  
  /*---------instantiate the minim objects----------*/
  //create the Minim object
  minim = new Minim(this);                                                
  
  //load the song (in the sketch directory) and set the  buffer size to 1024
  player = minim.loadFile("Wet.mp3", 1024);                               
  
  //strip and store the id3 tags from the mp3
  metaData = player.getMetaData();                                        
  
  //create the Fourier transform object, passing in the sample rate and buffersize
  fft = new FFT(player.bufferSize(), player.sampleRate());                
  
  
  /*---------Create all of the dots------*/
  //arrived at 1400 through trial and error of what filled up the title. They are instantiated
  //before the animation starts to decrease lag. Most are not used after intro. They are added
  //to the Dots array for easy access.
  numDots = 1400;                                                          
  dots = new Dots[numDots];           
  
  for(int i = 0; i < numDots; i++)                                         
  {
    dots[i] = new Dots(); 
  }
  
  /*-----------------Intro---------------*/
  //The title displayed in the intro.
  title = "Noise?";                  
  
  //Font was created using Tools>CreateFont. It is loaded for the intro text
  textFont(loadFont("Gisha-Bold-200.vlw"));                                
  textSize(130);                                                        
  
  //place the text based on its center point (x and y)
  textAlign(CENTER,CENTER);                                                
  
  //8 second fade in time (time of blurryness)
  fadeInTime = 8000;                                                       
  fadeValue = 0;                                          
  
  //allow for two seconds on non-blurry
  introTime = fadeInTime + 2000;                                           
  
  //calls prep intro to load dot placement before animation starts. Again, trying to decrease lag
  prepIntro();                                                             
  
  //start the song after the intro is loaded and started
  player.play();                                                           
}


//This method returns the linear interpolation color between two control
//colors (param 1 and 2). The weight is the third value and should only be
//between the values of 0 and 1. (0 being 100 % the first color and 1 being
//100% the second color). This method uses bit-shifting to drastically increase
//its speed since it is used after the animation is already started
color linearColorInterpolate(color startColor, color endColor, float weight)
{
  return color(
    ((1 - weight) * (startColor >> 16 & 0xFF) + weight * (endColor >> 16 & 0xFF)),
    ((1 - weight) * (startColor >> 8 & 0xFF) + weight * (endColor >> 8 & 0xFF)),
    ((1 - weight) * (startColor & 0xFF) + weight * (endColor & 0xFF)));    
}


//This method prepares for the intro by arranging all of the dots in the shape
//of the title text specified in setup. It then logs the time at which the intro
//can commence.
void prepIntro()
{
  background(colors[11]);                                                      
  color textColor = colors[3];                                                 
  fill(textColor);                                                         
  
  //Draw the title text to the dead center of the screen
  text(title, width/2,height/2);                                           
  
  //save the current frame to the sketch directory as a placement map for the dots
  saveFrame("alphaMask.tif");                                              
  
  //load the image that was just saved
  PImage mask = loadImage("alphaMask.tif");                                
  
  //set fill color to black and draw a rectangle. This is to prevent the viewer from
  fill(0);                                                                 
  
  //seeing the alpha map during load time
  rect(0,0,width,height);                                                  
  
  //load the alpha map pixels into an array
  mask.loadPixels();                                                       
  
  //determine the width of the title text to limit the range on the random placement of dots
  float titleLength = textWidth(title);                                    
  
  //determine the left-most horizontal pixel value to be included in the random range
  float xbounds = width/2 - titleLength/2;                                 
  int x, y;
  
  //loop through all of the dots until they are all placed within the title text
  for (int i = 0; i < numDots; i++)                                        
  {
    //determine a random x value with the given constraints
     x = (int)random(xbounds, xbounds + titleLength);                      
     
     //Couldn't find a method that would yeild the height of a string but it could probably be calc'ed with textSize
     y = (int)random(height/2 - 100, height/2 +100);                       
     
     //check if the random x,y coord lies within the text in the alpha map by checking its color
     if(mask.pixels[x + mask.width * y] == textColor)                      
     {
       //if it is... assign the position to the current dot, and set a random radius and color
       dots[i].position.x = x;                                              
       dots[i].position.y = y;
       dots[i].radius = (int)random(5,12);
       
       //color is actually set based on the array position but since screen position is random, the color seems random
       dots[i].myColor = colors[i % 14];                                    
       
       //disable the pshape style to use the default processing styles. Ran out of time on fleshing out Dots class.
       dots[i].DisableStyle();                                              
       
     }
     else
     {
       //if the coord was unsuccessfull, de-increment i to try again
       i--; 
     }                                                               
  }
  saveFrame("colors.png");                                                  
  
  //note the time that loading has completed so that animation times can used this in calculation deltaTime
  introStartTime = millis();                                                
}

/*---------Drawing fields-------*/
//the horizontal start point for the end credit text
int ys = 15;                                                                

//the delta y change for new text lines at the end
int yi = 15;                                                                
float index = 0;                          

//helps make sure the disintegrate method is only called once
boolean disintegrated = false;                                              
boolean startedSong = false;
boolean startedPhase2 = false;

//notes the start time of animation sequence 2. An attempt to keep slower computers on track
float phase2StartTime = -10;                                                
float phase2TotalTime = 20000;                                              
float phase2FadeInTime = 3000;

//the radius of the main character ellipse
float tempRadius = 200;                                                     

//stores buffer index values so they only have to be called once
float waveformValue = 0;                                                    
float waveformValue2 = 0;

//stores the theta for the rotating orbs
float theta = 0;                                                             

//the separation in degrees of the orbs (8 of them)
float deltaTheta = 360/8;                                                    
float elapsed;

void draw()
{ 
  //ensures drawing does not take place until loading is complete
 if(introStartTime < 0)                                                      
 {  
   return;
 }

 //check time bounds for the intro animation sequence
 if(introTime + 5000 > millis() - introStartTime)                            
 {
   //introduction sequence
   //determine if the animation should be fading in
   if(fadeInTime > millis() - introStartTime)                                
   {
     background(colors[11]);                                                 
     
     //draw all of the dots that are already pre-positioned
     for(int i = 0; i < numDots; i++)                                        
     {
        dots[i].drawDot(); 
     }                                                             
     
     //animate the fill color based on time since animation started
     fill(120,120,120,255 - ((float)(millis() - introStartTime)/introTime)*255);
     
     //draw over the screen with decreaseing opacity to mimick fade in
     rect(0,0,width,height);                                                  
     
     //determine if the image should be blurry then use filter to apply Guassian blur
     if(millis() - introStartTime < fadeInTime)                               
      filter(BLUR,fadeInTime/1000 - (float)(millis() - introStartTime)/((float)1000));
   }
   else if((introTime > millis() - introStartTime))
   {
     //start the song if it has not already been started
     if(!startedSong)                                                          
     {
       startedSong = true; 
     }
     //set true background color
     background(colors[11]);                                                    
     for(int i = 0; i < numDots; i++)
     {  
       //draw all of the pre-placed dots
        dots[i].drawDot();                                                       
     }
   }
   //check if it is time to detonate
   else if((introTime + 3000 > millis() - introStartTime))                      
   {
     //ensure detonation has not already occured
     if(!disintegrated)                                                         
     {
       //apply an acceleration to all of the dots (completely psuedo-random)
       for(int i = 0; i < numDots; i++)                                          
       {
          dots[i].applyForce(random(-5,5), random(-5,5));
       }
       disintegrated = true; 
     }
     background(colors[11]);
     for(int i = 0; i < numDots; i++)
     {
       //continually update dots positions and draw them
        dots[i].update();                                                        
        dots[i].drawDot(); 
     }
   }
   //if it is time to fade out, continue dot work but layer
   //over more and more opaque rectangles
   else                                                                         
   {                                                                           
     background(colors[11]);
     for(int i = 0; i < numDots; i++)
     {
        dots[i].update();
        dots[i].drawDot(); 
     }
     fill(colors[11], 255 * (2000 - (float)(introTime + 5000 - millis() + introStartTime))/2000);
     rect(0,0,width,height);
   }
   //prevent other sequences from drawing
   return;                                                                      
 }
 
 //all of the setup required for just anim2
 if(!startedPhase2)                                                             
 {                                                                              
   //make sure setup only occurs once
   startedPhase2 = true;                                          
   
   //note the start time for delta calcs
   phase2StartTime = millis();                                                  
   
   //setup background scenery dots
    for (int i = 40; i < 200; i++)                                               
    {
        //they all track from left to right so they are positioned far right
        dots[i].position.x = width - 1;                                         
        
        //the vert position is determined with gaussian to spawn more towards the middle although this is dampened
        dots[i].position.y = abs(randomGaussian()) * height / 2;                
        
        //keep the dots in bounds
        dots[i].position.y = constrain(dots[i].position.y, 0, height);          
        
        //add slight variation to keep them from being in a line
        dots[i].position.y *= random(.9,1.1);                                   
        
        //vary the horzontal velocity with Guass to keep it fairly consistant but still random looking
        dots[i].velocity.x = abs(randomGaussian()) * - 3;                       
        
        //start off with no vertical velocity
        dots[i].velocity.y = 0;                                                 
      }      
 }
 
 //increment theta to make orbs move
 theta++;                                                                       
 
 //black background for space-look
 background(0);                                                                 
 
 //draw ellipses from the center
 ellipseMode(CENTER);                                                           
   //use the fourier transfrom data (lower end near the kick) to drive the radius of the chracter but contrain it to keep it in bounds
   if(constrain(fft.getBand(3) * 10, 170, 230) > tempRadius)
     tempRadius = constrain(fft.getBand(3) * 10, 170, 230);
   
   //set a decay rate for the charcter to slowly bring back its radius to min levels
   tempRadius *= .90;                                                           
   tempRadius = constrain(tempRadius, 170, 230);
   
   //checks for fade in time for anim 2
   if(phase2StartTime + phase2FadeInTime > millis())                            
   {
        //looping through all of the scenery ellipses
        for (int i = 40; i < 200; i++)                                          
        {                                                                       
          //check bounds
          if(dots[i].position.x < 0 ||dots[i].position.x > width || dots[i].position.y < 0 || dots[i].position.y > height)
          {                                                                     
            //reposition the ellipses if they track out of bounds
            dots[i].position.x = width - 1;
            dots[i].position.y = abs(randomGaussian()) * height / 2;
            dots[i].position.y = constrain(dots[i].position.y, 0, height);
            dots[i].position.y *= random(.9,1.1);
            dots[i].velocity.x = abs(randomGaussian()) * - 3;
            dots[i].velocity.y = noise(dots[i].position.x);
          }
          
          // use perlin noise to add very small deviations in vertical velocity based on x position. Not a very noticable flow field type effect
          dots[i].velocity.y *= (4 * noise(dots[i].position.x) - 2);            
          
          //update phys values
          dots[i].update();                                                     
          
          //draw the dots
          dots[i].drawDot();                                                    
        }
        
       stroke(255,255,255, 225 - 255 * (phase2FadeInTime - (float)(millis() - phase2StartTime))/phase2FadeInTime);
       
       //looping through the buffer to draw the waveforms
       for(int i = 0; i < player.bufferSize() - 1; i++)                          
       {
          //the upper line and the lowever line connecting adjacent values in the buffer array with a thin white line
          line(i, 50 + player.right.get(i)*50, i+1, 50 + player.right.get(i+1)*50);
          line(i, height - 50 + player.right.get(i)*50, i+1, height - 50 + player.right.get(i+1)*50);
       }
       
       fill(colors[0]);
       stroke(colors[4]);
       strokeWeight(9);
       
       //draw the charcter after setting style attributes for it.
       ellipse(width/2, height/2, tempRadius, tempRadius);                       
       strokeWeight(1);
       
       //Fast Fourier Transform
       fft.forward(player.mix);
       
       //spectrograph
       //loop through fft data to draw the spectrogram
       for(float i = 0; i < fft.specSize(); i++)                                 
       {
         //draw spectrogram on the far right size with interpolated colors
         stroke(linearColorInterpolate(colors[4], colors[9],(i/fft.specSize()*2)));
         line(width, i, width - fft.getBand((int)i/2)*4, i);
       }
      
        //control the orbs with trig
        for (int i = 0; i < 8; i++)                                              
        {
          dots[i].radius = 20;
          dots[i].position.x = width/2 + tempRadius/1.5 * sin(radians(theta)) + dots[i].radius * sin(radians(theta)) + 30;
          dots[i].position.y = height/2 + tempRadius/1.5 * cos(radians(theta)) + dots[i].radius * cos(radians(theta)) + 30;
          dots[i].drawDot();
          theta += deltaTheta;
        }

        fill(colors[11], 255 * (phase2FadeInTime - (float)(millis() - phase2StartTime))/phase2FadeInTime);
        stroke(255,255,255, 225 - 255 * (phase2FadeInTime - (float)(millis() - phase2StartTime))/phase2FadeInTime);
        rect(0,0,width,height);
   }
   //everything is the same but the fade period is over.
   else                                                                            
   {
        for (int i = 40; i < 200; i++)
        {
          if(dots[i].position.x < 0 ||dots[i].position.x > width || dots[i].position.y < 0 || dots[i].position.y > height)
          {
            dots[i].position.x = width - 1;
            dots[i].position.y = abs(randomGaussian()) * height / 2;
            dots[i].position.y = constrain(dots[i].position.y, 0, height);
            dots[i].position.y *= random(.9,1.1);
            dots[i].velocity.x = abs(randomGaussian()) * - 3;
            dots[i].velocity.y = noise(dots[i].position.x);
          }
          dots[i].velocity.y *= (4 * noise(dots[i].position.x) - 2);
          dots[i].update();
          dots[i].drawDot();
        }

     stroke(255);
       for(int i = 0; i < player.bufferSize() - 1; i++)
       {
          line(i, 50 + player.right.get(i)*50, i+1, 50 + player.right.get(i+1)*50);
          line(i, height - 50 + player.right.get(i)*50, i+1, height - 50 + player.right.get(i+1)*50);
       }
       fill(colors[0]);
       stroke(colors[4]);
       strokeWeight(9);
       ellipse(width/2, height/2, tempRadius, tempRadius);       
       strokeWeight(1);
       
       //Fast Fourier Transform
       fft.forward(player.mix);
       
       //spectrograph
       for(float i = 0; i < fft.specSize(); i++)
       {
         stroke(linearColorInterpolate(colors[4], colors[9],(i/fft.specSize()*2)));
         line(width, i, width - fft.getBand((int)i/2)*4, i);
       }
       
       
        for (int i = 0; i < 8; i++)
        {
          dots[i].radius = 20;
          dots[i].position.x = width/2 + tempRadius/1.5 * sin(radians(theta)) + dots[i].radius * sin(radians(theta));
          dots[i].position.y = height/2 + tempRadius/1.5 * cos(radians(theta)) + dots[i].radius * cos(radians(theta));
          dots[i].drawDot();
          theta += deltaTheta;
        }
   }
   
  //when the song is complete, show the song, author information, etc with smaller font
  if(millis() > 210000)                                                            
  {
   textFont(loadFont("Gisha-48.vlw"));
   textSize(18);
   textAlign(LEFT);
   
   //description
   fill(255,255,255);
   int y = height/2 - 50;
   text("Title: " + metaData.title(), 5, y);
   text("Author: " + metaData.author(), 5, y+=yi);
   text("Length: " + metaData.length() / 1000 + " seconds", 5, y+=yi);
  }
 
}