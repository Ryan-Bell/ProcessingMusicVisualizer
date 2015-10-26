class Dots
{
  PShape self;
  PVector position, velocity, acceleration;
  color myColor;
  float radius;
  boolean enableDrag = true;
  boolean stroke = false;
  float dragConst = 1;
  float theta;
  
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
  
  void DisableStyle()
  {
    self.disableStyle(); 
  }
  
  void applyForce(float xforce, float yforce)
  {
    acceleration.x = xforce;
    acceleration.y = yforce;
  }  
  
  void incTheta(float angle)
  {
    theta += angle;
    theta %= 360;
  }
  
  void update()
  {
    position.add(velocity);
    velocity.add(acceleration);
    if (enableDrag)
    {acceleration.mult(dragConst/radius);}
  }
  
  void drawDot()
  {
    fill(myColor);
    noStroke();
    shapeMode(CENTER);
    shape(self, position.x, position.y, radius, radius);
    
  }
  
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