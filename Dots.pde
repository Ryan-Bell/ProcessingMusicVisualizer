class Dots
{
  PShape self;
  //vectors used in physics based animation and drawing
  PVector position, velocity, acceleration;
  //This specifies the fill color specific to this dot
  color myColor;
  float radius;
  //Determines whether velocity should degrade 
  boolean enableDrag = true;
  //determines whether the dot should be drawn with an outline
  boolean stroke = false;
  //The strength of the drag
  float dragConst = 1;
  //The float that will hold the rotational value for the center dots
  float theta;
  
  //The following four constructors allow for greater and greater specificity
  //during the instantiation of a dot object. At the lower levels, values not 
  //passed in as parameters are simply set to a default value.
  Dots()
  {
    position = new PVector(0, 0);
    velocity = new PVector(0, 0);
    acceleration = new PVector(0, 0);
    myColor = color(128,128,128);
    radius = 10;
    shapeMode(CENTER);
    self = createShape(ELLIPSE, 0, 0, radius, radius);
  }
  
  Dots(float x, float y, color c, float rad)
  {
    position = new PVector(x, y);
    velocity = new PVector(0, 0);
    acceleration = new PVector(0, 0);
    myColor = c;
    radius = rad;
    shapeMode(CENTER);
    self = createShape(ELLIPSE, x, y, radius, radius);
  }
  
  Dots(float x, float y, float xspeed, float yspeed, color c, float rad)
  {
    position = new PVector(x, y);
    velocity = new PVector(xspeed, yspeed);
    acceleration = new PVector(0, 0);
    myColor = c;
    radius = rad;
    shapeMode(CENTER);
    self = createShape(ELLIPSE, x, y, radius, radius);
  }
  
  Dots(float x, float y, float xspeed, float yspeed, float xaccel, float yaccel, color c, float rad)
  {
    position = new PVector(x, y);
    velocity = new PVector(xspeed, yspeed);
    acceleration = new PVector(xaccel, yaccel);
    myColor = c;
    radius = rad;
    shapeMode(CENTER);
    self = createShape(ELLIPSE, x, y, radius, radius);
  }
  
  //This method is called when the pshape specific style needs to be overridden
  void DisableStyle()
  {
    self.disableStyle(); 
  }
  
  //This method allows for the easy animation of the dots by adding a force
  //The resulting pseudo-physics are calculated in update
  void applyForce(float xforce, float yforce)
  {
    acceleration.x = xforce;
    acceleration.y = yforce;
  }  
  
  //This method is used for the rotating spheres in the center of the screen
  void incTheta(float angle)
  {
    theta += angle;
    theta %= 360;
  }
  
  //This method updates the pseudo-physics for the dots and thus, 
  //the force based animation
  void update()
  {
    position.add(velocity);
    velocity.add(acceleration);
    if (enableDrag)
    {acceleration.mult(dragConst/radius);}
  }
  
  //handles drawing the dot to the screen with the internal style 
  void drawDot()
  {
    fill(myColor);
    noStroke();
    shapeMode(CENTER);
    shape(self, position.x, position.y, radius, radius);
  }
  
  //an overloaded drawDot method that can be used to draw the dot at a 
  //specific location. This allows movement to be set without having to use 
  //the addForce method
  void drawDot(int x, int y)
  {
    shapeMode(CENTER);
    fill(myColor);
    noStroke();
    pushMatrix();
    translate(x,y);
    shape(self);
    popMatrix();
  } 
}