
// Expr ::= Val { BinaryOperator Val }
class Expr extends ASTList{
  final int maxlevel = 5;
  ArrayList<BinaryOperator> ops;
  Expr(TokenList tl){
    ops = new ArrayList<BinaryOperator>();
    children.add(new Val(tl));
    while(tl.isBinaryOperator()){
      ops.add(tl.readBinaryOperator());
      children.add(new Val(tl));
    }
  }
  
  // slow...
  Object eval(int k, Environment e){
    ArrayList<Object> vals = new ArrayList<Object>();
    for(AST v: children){
      vals.add(((Val)v).eval(k+1, e));
    }
    
    ArrayList<BinaryOperator> ops_cpy = new ArrayList<BinaryOperator>(ops);
    ArrayList<BinaryOperator> ops_cpy_ = new ArrayList<BinaryOperator>();
    ArrayList<Object> vals_ = new ArrayList<Object>();
    for(int il=0; il<maxlevel; il++){
      ops_cpy_.clear();
      vals_.clear();
      vals_.add(vals.get(0));
      for(int i=0; i<ops_cpy.size(); i++){
        /*
        if(DEBUG){
          println(il + " " + i + " " + ops.get(i).level);
          ops.get(i).print();
        }
        */
        if(ops_cpy.get(i).level==il){
          vals_.add(ops_cpy.get(i).eval(vals_.remove(vals_.size()-1), vals.get(i+1)));
        }else{
          vals_.add(vals.get(i+1));
          ops_cpy_.add(ops_cpy.get(i));
        }
      }
      ops_cpy = new ArrayList<BinaryOperator>(ops_cpy_);
      vals = new ArrayList<Object>(vals_);
    }
    return vals.get(0);
  }
}

abstract class BinaryOperator{
  int level;
  Object eval(Object x, Object y){
    return null;
  }
  void print(){
  }
}

class MultOp extends BinaryOperator{
  MultOp(){
    level = 0;
  }
  Object eval(Object x, Object y){
    if(x instanceof Integer && y instanceof Integer){
      return (Integer)x * (Integer)y;
    }
    return null;
  }
  void print(){
    println("*");
  }
}

class DivOp extends BinaryOperator{
  DivOp(){
    level = 0;
  }
  Object eval(Object x, Object y){
    if(x instanceof Integer && y instanceof Integer){
      return (Integer)x / (Integer)y;
    }
    return null;
  }
  void print(){
    println("/");
  }
}

class ModOp extends BinaryOperator{
  ModOp(){
    level = 0;
  }
  Object eval(Object x, Object y){
    if(x instanceof Integer && y instanceof Integer){
      return (Integer)x % (Integer)y;
    }
    return null;
  }
  void print(){
    println("%");
  }
}

class PlusOp extends BinaryOperator{
  PlusOp(){
    level = 1;
  }
  Object eval(Object x, Object y){
    if(x instanceof Integer && y instanceof Integer){
      return (Integer)x + (Integer)y;
    }
    return null;
  }
  void print(){
    println("+");
  }
}

class MinusOp extends BinaryOperator{
  MinusOp(){
    level = 1;
  }
  Object eval(Object x, Object y){
    if(x instanceof Integer && y instanceof Integer){
      return (Integer)x - (Integer)y;
    }
    return null;
  }
  void print(){
    println("-");
  }
}

class LTOp extends BinaryOperator{
  LTOp(){
    level = 2;
  }
  Object eval(Object x, Object y){
    if(x instanceof Integer && y instanceof Integer){
      return (Integer)x < (Integer)y;
    }
    return null;
  }
  void print(){
    println("<");
  }
}

class LTEOp extends BinaryOperator{
  LTEOp(){
    level = 2;
  }
  Object eval(Object x, Object y){
    if(x instanceof Integer && y instanceof Integer){
      return (Integer)x <= (Integer)y;
    }
    return null;
  }
  void print(){
    println("<=");
  }
}

class GTOp extends BinaryOperator{
  GTOp(){
    level = 2;
  }
  Object eval(Object x, Object y){
    if(x instanceof Integer && y instanceof Integer){
      return (Integer)x > (Integer)y;
    }
    return null;
  }
  void print(){
    println(">");
  }
}

class GTEOp extends BinaryOperator{
  GTEOp(){
    level = 2;
  }
  Object eval(Object x, Object y){
    if(x instanceof Integer && y instanceof Integer){
      return (Integer)x >= (Integer)y;
    }
    return null;
  }
  void print(){
    println(">=");
  }
}
class EqOp extends BinaryOperator{
  EqOp(){
    level = 3;
  }
  Object eval(Object x, Object y){
    if(x instanceof Integer && y instanceof Integer){
      return (Integer)x == (Integer)y;
    }
    else if(x instanceof Boolean && y instanceof Boolean){
      return (Boolean)x == (Boolean)y;
    }
    return null;
  }
  void print(){
    println("==");
  }
}
class NEqOp extends BinaryOperator{
  NEqOp(){
    level = 3;
  }
  Object eval(Object x, Object y){
    if(x instanceof Integer && y instanceof Integer){
      return (Integer)x != (Integer)y;
    }
    else if(x instanceof Boolean && y instanceof Boolean){
      return (Boolean)x != (Boolean)y;
    }
    return null;
  }
  void print(){
    println("!=");
  }
}
class AndOp extends BinaryOperator{
  AndOp(){
    level = 4;
  }
  Object eval(Object x, Object y){
    if(x instanceof Boolean && y instanceof Boolean){
      return (Boolean)x && (Boolean)y;
    }
    return null;
  }
  void print(){
    println("&&");
  }
}
class OrOp extends BinaryOperator{
  OrOp(){
    level = 4;
  }
  Object eval(Object x, Object y){
    if(x instanceof Boolean && y instanceof Boolean){
      return (Boolean)x || (Boolean)y;
    }
    return null;
  }
  void print(){
    println("||");
  }
}
