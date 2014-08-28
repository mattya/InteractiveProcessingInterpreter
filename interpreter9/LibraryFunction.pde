
void addLibraryFunctions(Environment e){
  e.put("ellipse", new ProcessingEllipse());
  e.put("rect", new ProcessingRect());
  e.put("stroke", new ProcessingStroke());
  e.put("fill", new ProcessingFill());
  e.put("noStroke", new ProcessingNoStroke());
  e.put("noFill", new ProcessingNoFill());
  
}

class ProcessingLine extends Function{
  ProcessingLine(){
  }
  Object call(Arguments args, int k, Environment e){
    float x = (Integer)args.children.get(0).eval(k+1, e);
    float y = (Integer)args.children.get(1).eval(k+1, e);
    float w = (Integer)args.children.get(2).eval(k+1, e);
    float h = (Integer)args.children.get(3).eval(k+1, e);
    line(x, y, w, h);
    return null;
  }
}
class ProcessingEllipse extends Function{
  ProcessingEllipse(){
  }
  Object call(Arguments args, int k, Environment e){
    float x = (Integer)args.children.get(0).eval(k+1, e);
    float y = (Integer)args.children.get(1).eval(k+1, e);
    float w = (Integer)args.children.get(2).eval(k+1, e);
    float h = (Integer)args.children.get(3).eval(k+1, e);
    ellipse(x, y, w, h);
    return null;
  }
}

class ProcessingRect extends Function{
  ProcessingRect(){
  }
  Object call(Arguments args, int k, Environment e){
    float x = (Integer)args.children.get(0).eval(k+1, e);
    float y = (Integer)args.children.get(1).eval(k+1, e);
    float w = (Integer)args.children.get(2).eval(k+1, e);
    float h = (Integer)args.children.get(3).eval(k+1, e);
    rect(x, y, w, h);
    return null;
  }
}
class ProcessingFill extends Function{
  ProcessingFill(){
  }
  Object call(Arguments args, int k, Environment e){
    float r = (Integer)args.children.get(0).eval(k+1, e);
    float g = (Integer)args.children.get(1).eval(k+1, e);
    float b = (Integer)args.children.get(2).eval(k+1, e);
    float a = 255;
    if(args.children.size()==4) a = (Integer)args.children.get(3).eval(k+1, e);
    fill(r, g, b, a);
    return null;
  }
}
class ProcessingStroke extends Function{
  ProcessingStroke(){
  }
  Object call(Arguments args, int k, Environment e){
    float r = (Integer)args.children.get(0).eval(k+1, e);
    float g = (Integer)args.children.get(1).eval(k+1, e);
    float b = (Integer)args.children.get(2).eval(k+1, e);
    float a = 255;
    if(args.children.size()==4) a = (Integer)args.children.get(3).eval(k+1, e);
    stroke(r, g, b, a);
    return null;
  }
}
class ProcessingNoFill extends Function{
  ProcessingNoFill(){
  }
  Object call(Arguments args, int k, Environment e){
    noFill();
    return null;
  }
}
class ProcessingNoStroke extends Function{
  ProcessingNoStroke(){
  }
  Object call(Arguments args, int k, Environment e){
    noStroke();
    return null;
  }
}
