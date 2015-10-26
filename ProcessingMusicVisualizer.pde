//Include all the packages from the minim audio analyzer library
import ddf.minim.*;
import ddf.minim.analysis.*;
import ddf.minim.effects.*;
import ddf.minim.signals.*;
import ddf.minim.spi.*;
import ddf.minim.ugens.*;

//Dots
Dots[] dots;                                                              //Dots array that will hold all of the dots for the entire sketch
int numDots;                                                              //The number of dots that will be created

//Color scheme constants
color purple1, purple2, purple3, purple4, purple5;                        //Will hold the rgb values for the 5 constant purple colors
color pink1, pink2, pink3, pink4, pink5;                                  //Will hold the rgb values for the 5 constant pink colors
color blue1, blue2, blue3, blue4, blue5;                                  //All of these values were determined outside of processing
color[] purples, pinks, blues, colors;                                    //Color arrays to sort colors and make accessing them easier

//minim audio object declarations
Minim minim;                                                              //The main manager for the minim audio library
AudioPlayer player;                                                       //This will hold all of the information about the song
AudioMetaData metaData;                                                   //This specifically holds info such as title, author, runtime, etc
FFT fft;                                                                  //This is the Fourier Fast Transform object that will be used for the spectrograph

//Intro
String title;                                                              //This holds the title that will be displayed in the beginning
float fadeInTime;                                                          //The time in millis of the fade in sequence for the intro
float fadeValue;                                                           //This keeps track of how blurry the screen should be
float introTime;                                                           //This stores the total time alloted for the intro
PShader blur;                                                              //This PShader object allows for fast Guassian blurring
float introStartTime = -10;                                                //This will keep track of the time the loading finishes

//All of the basic declarations are
//ofund in the setup. 
void setup()
{
  size(1024,480,P3D);                                                      //The horizontal size is very specific as it matches the buffer length
                                                                           //for the song. It should only be a power of two. 
  //set values for the color constants
  purple1 = color(173,129,196);                                            //predetermined rgb values are set for the colors
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
  purples = new color[5];                                                  //The purple array will store the five purple colors
  pinks = new color[5];                                                    //--
  blues = new color[5];                                                    //--
  colors = new color[15];                                                  //The color array will store all of the colors
  purples[0] = purple1;                                                    //adding of the colors to the arrays
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
  for(int i = 0; i < 5; i++)                                              //iterating over the length of each of the indiv. color arrays to add
  {                                                                       //them to the master array. I didn't want an array of arrays.
    colors[i] = purples[i];                                               //purples take spots 0-4, pink 5-9, blues 10- 14
    colors[i+5] = pinks[i];
    colors[i+10] = blues[i];
  }
  

  
  //instantiate the minim objects
  minim = new Minim(this);                                                //create the Minim object
  player = minim.loadFile("Wet.mp3", 1024);                               //load the song (in the sketch directory) and set the  buffer size to 1024
  metaData = player.getMetaData();                                        //strip and store the id3 tags from the mp3
  fft = new FFT(player.bufferSize(), player.sampleRate());                //create the Fourier transform object, passing in the sample rate and buffersize
  
  //Create all of the dots
  numDots = 1400;                                                          //arrived at 1400 through trial and error of what filled up the title. They are instantiated
  dots = new Dots[numDots];                                                //before the animation starts to decrease lag. Most are not used after intro. They are added
  for(int i = 0; i < numDots; i++)                                         //to the Dots array for easy access.
  {
    dots[i] = new Dots(); 
  }
  
  //Intro
  title = "Noise?";                                                        //The title displayed in the intro. 
  textFont(loadFont("Gisha-Bold-200.vlw"));                                //Font was created using Tools>CreateFont. It is loaded for the intro text
  textSize(130);                                                        
  textAlign(CENTER,CENTER);                                                //place the text based on its center point (x and y)
  fadeInTime = 8000;                                                       //8 second fade in time (time of blurryness)
  fadeValue = 0;                                          
  introTime = fadeInTime + 2000;                                           //allow for two seconds on non-blurry
  prepIntro();                                                             //calls prep intro to load dot placement before animation starts. Again, trying to decrease lag
  player.play();                                                           //start the song after the intro is loaded and started
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
  text(title, width/2,height/2);                                           //Draw the title text to the dead center of the screen
  saveFrame("alphaMask.tif");                                              //save the current frame to the sketch directory as a placement map for the dots
  PImage mask = loadImage("alphaMask.tif");                                //load the image that was just saved
  fill(0);                                                                 //set fill color to black and draw a rectangle. This is to prevent the viewer from 
  rect(0,0,width,height);                                                  //seeing the alpha map during load time
  mask.loadPixels();                                                       //load the alpha map pixels into an array
  float titleLength = textWidth(title);                                    //determine the width of the title text to limit the range on the random placement of dots
  float xbounds = width/2 - titleLength/2;                                 //determine the left-most horizontal pixel value to be included in the random range
  int x, y;
  for (int i = 0; i < numDots; i++)                                        //loop through all of the dots until they are all placed within the title text
  {
     x = (int)random(xbounds, xbounds + titleLength);                      //determine a random x value with the given constraints
     y = (int)random(height/2 - 100, height/2 +100);                       //Couldn't find a method that would yeild the height of a string but it could probably be calc'ed with textSize 
     if(mask.pixels[x + mask.width * y] == textColor)                      //check if the random x,y coord lies within the text in the alpha map by checking its color
     {
       dots[i].position.x = x;                                              //if it is... assign the position to the current dot, and set a random radius and color
       dots[i].position.y = y;
       dots[i].radius = (int)random(5,12);
       dots[i].myColor = colors[i % 14];                                    //color is actually set based on the array position but since screen position is random, the color seems random
       dots[i].DisableStyle();                                              //disable the pshape style to use the default processing styles. Ran out of time on fleshing out Dots class.
       
     }
     else
     { i--; }                                                               //if the coord was unsuccessfull, de-increment i to try again
  }
  saveFrame("colors.png");                                                  //eh, why not?
  introStartTime = millis();                                                //note the time that loading has completed so that animation times can used this in calculation deltaTime
}

//Drawing fields
int ys = 15;                                                                //the horizontal start point for the end credit text    
int yi = 15;                                                                //the delta y change for new text lines at the end
float index = 0;                          
boolean disintegrated = false;                                              //helps make sure the disintegrate method is only called once
boolean startedSong = false;                                                //--
boolean startedPhase2 = false;                                              //--
float phase2StartTime = -10;                                                //notes the start time of animation sequence 2. An attempt to keep slower computers on track
float phase2TotalTime = 20000;                                              
float phase2FadeInTime = 3000;
float tempRadius = 200;                                                     //the radius of the main character ellipse
float waveformValue = 0;                                                    //stores buffer index values so they only have to be called once
float waveformValue2 = 0;
float theta = 0;                                                             //stores the theta for the rotating orbs
float deltaTheta = 360/8;                                                    //the separation in degrees of the orbs (8 of them)
float elapsed;

void draw()
{ 
 if(introStartTime < 0)                                                      //ensures drawing does not take place until loading is complete
 {  
   return;
 }
   
 if(introTime + 5000 > millis() - introStartTime)                            //check time bounds for the intro animation sequence
 {
   //introduction sequence
   if(fadeInTime > millis() - introStartTime)                                //determine if the animation should be fading in
   {
     background(colors[11]);                                                 
     for(int i = 0; i < numDots; i++)                                        //draw all of the dots that are already pre-positioned
     {
        dots[i].drawDot(); 
     }                                                                        //animate the fill color based on time since animation started
     fill(120,120,120,255 - ((float)(millis() - introStartTime)/introTime)*255);
     rect(0,0,width,height);                                                  //draw over the screen with decreaseing opacity to mimick fade in
     if(millis() - introStartTime < fadeInTime)                               //determine if the image should be blurry then use filter to apply Guassian blur
      filter(BLUR,fadeInTime/1000 - (float)(millis() - introStartTime)/((float)1000));
   }
   else if((introTime > millis() - introStartTime))
   {
     if(!startedSong)                                                          //start the song if it has not already been started
     {
       startedSong = true; 
     }
     background(colors[11]);                                                    //set true background color
     for(int i = 0; i < numDots; i++)
     {  
        dots[i].drawDot();                                                      //draw all of the pre-placed dots 
     }
   }
   else if((introTime + 3000 > millis() - introStartTime))                      //check if it is time to detonate
   {
     if(!disintegrated)                                                         //ensure detonation has not already occured
     {
       for(int i = 0; i < numDots; i++)                                          //apply an acceleration to all of the dots (completely psuedo-random)
       {
          dots[i].applyForce(random(-5,5), random(-5,5));
       }
       disintegrated = true; 
     }
     background(colors[11]);
     for(int i = 0; i < numDots; i++)
     {
        dots[i].update();                                                        //continually update dots positions and draw them
        dots[i].drawDot(); 
     }
   }
   else                                                                        //if it is time to fade out, continue dot work but layer 
   {                                                                           //over more and more opaque rectangles
     background(colors[11]);
     for(int i = 0; i < numDots; i++)
     {
        dots[i].update();
        dots[i].drawDot(); 
     }
     fill(colors[11], 255 * (2000 - (float)(introTime + 5000 - millis() + introStartTime))/2000);
     rect(0,0,width,height);
   }
   return;                                                                      //prevent other sequences from drawing
 }
 
 if(!startedPhase2)                                                             //all of the setup required for just anim2
 {                                                                              //make sure setup only occurs once
   startedPhase2 = true;                                          
   phase2StartTime = millis();                                                  //note the start time for delta calcs              
    for (int i = 40; i < 200; i++)                                              //setup background scenery dots 
    {
        dots[i].position.x = width - 1;                                         //they all track from left to right so they are positioned far right
        dots[i].position.y = abs(randomGaussian()) * height / 2;                //the vert position is determined with gaussian to spawn more towards the middle although this is dampened
        dots[i].position.y = constrain(dots[i].position.y, 0, height);          //keep the dots in bounds
        dots[i].position.y *= random(.9,1.1);                                   //add slight variation to keep them from being in a line
        dots[i].velocity.x = abs(randomGaussian()) * - 3;                       //vary the horzontal velocity with Guass to keep it fairly consistant but still random looking 
        dots[i].velocity.y = 0;                                                 //start off with no vertical velocity
      }      
 }
 theta++;                                                                       //increment theta to make orbs move
 background(0);                                                                 //black background for space-look
 ellipseMode(CENTER);                                                           //draw ellipses from the center
                                                                                //use the fourier transfrom data (lower end near the kick) to drive the radius of the chracter but contrain it to keep it in bounds
   if(constrain(fft.getBand(3) * 10, 170, 230) > tempRadius)
     tempRadius = constrain(fft.getBand(3) * 10, 170, 230);
   
   tempRadius *= .90;                                                           //set a decay rate for the charcter to slowly bring back its radius to min levels
   tempRadius = constrain(tempRadius, 170, 230);
   if(phase2StartTime + phase2FadeInTime > millis())                            //checks for fade in time for anim 2
   {
        for (int i = 40; i < 200; i++)                                          //looping through all of the scenery ellipses
        {                                                                       //check bounds
          if(dots[i].position.x < 0 ||dots[i].position.x > width || dots[i].position.y < 0 || dots[i].position.y > height)
          {                                                                     //reposition the ellipses if they track out of bounds 
            dots[i].position.x = width - 1;
            dots[i].position.y = abs(randomGaussian()) * height / 2;
            dots[i].position.y = constrain(dots[i].position.y, 0, height);
            dots[i].position.y *= random(.9,1.1);
            dots[i].velocity.x = abs(randomGaussian()) * - 3;
            dots[i].velocity.y = noise(dots[i].position.x);
          }
          dots[i].velocity.y *= (4 * noise(dots[i].position.x) - 2);            // use perlin noise to add very small deviations in vertical velocity based on x position. Not a very noticable flow field type effect
          dots[i].update();                                                     //update phys values
          dots[i].drawDot();                                                    //draw the dots
        }
        
       stroke(255,255,255, 225 - 255 * (phase2FadeInTime - (float)(millis() - phase2StartTime))/phase2FadeInTime);
       for(int i = 0; i < player.bufferSize() - 1; i++)                          //looping through the buffer to draw the waveforms
       {
          line(i, 50 + player.right.get(i)*50, i+1, 50 + player.right.get(i+1)*50);//the upper line and the lowever line connecting adjacent values in the buffer array with a thin white line
          line(i, height - 50 + player.right.get(i)*50, i+1, height - 50 + player.right.get(i+1)*50);
       }
       fill(colors[0]);
       stroke(colors[4]);
       strokeWeight(9);
       ellipse(width/2, height/2, tempRadius, tempRadius);                       //draw the charcter after setting style attributes for it.
       strokeWeight(1);
       //Fast Fourier Transform
       fft.forward(player.mix);                                                  //calculate fft
       //spectrograph
       for(float i = 0; i < fft.specSize(); i++)                                 //loop through fft data to draw the spectrogram
       {
         stroke(linearColorInterpolate(colors[4], colors[9],(i/fft.specSize()*2)));//draw spectrogram on the far right size with interpolated colors
         line(width, i, width - fft.getBand((int)i/2)*4, i);
       }
      
        for (int i = 0; i < 8; i++)                                              //control the orbs with trig
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
   else                                                                            //everything is the same but the fade period is over.
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
   
if(millis() > 210000)                                                            //when the song is complete, show the song, author information, etc with smaller font
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