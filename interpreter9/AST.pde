class AST{
  int num_token = 0;
  boolean ok = false;
  Object eval(int k, Environment e){return null;}
}

class ASTList extends AST{
  ArrayList<AST> children;
  ASTList(){
    children = new ArrayList<AST>();
  }
}

class Name extends ASTList{
  String name;
  Name(String s){
    name = s;
  }
  Object eval(int k, Environment e){
    throw new RuntimeException();
  }
}

class Number extends ASTList{
  int num;
  Number(int n0){
    num = n0;
  }
  Object eval(int k, Environment e){
    return num;
  }
}



// Val ::= '(' Expr ')' | Number | NamedElement
class Val extends ASTList{
  Val(TokenList tl){
    if(tl.isOperator("(")){
      tl.readOperator("(");
      children.add(new Expr(tl));
      tl.readOperator(")");
    }else if(tl.isNumber()){
      children.add(tl.readNumber());
    }else if(tl.isName()){
      children.add(new NamedElement(tl));
    }else{
      throw new ParseException();
    }
  }
  Object eval(int k, Environment e){
    return children.get(0).eval(k+1, e);
  }
}

// NamedElement ::= Name [ "(" [Arguments] ")" | "[" Expr "]" ]
class NamedElement extends ASTList{
  boolean isFunccall = false;
  boolean isArray = false;
  NamedElement(TokenList tl){
    if(tl.isName()){
      children.add(tl.readName());
      if(tl.isOperator("(")){
        tl.readOperator("(");
        if(!tl.isOperator(")")) children.add(new Arguments(tl));
        tl.readOperator(")");
        isFunccall = true;
      }else if(tl.isOperator("[")){
        tl.readOperator("[");
        children.add(new Expr(tl));
        tl.readOperator("]");
        isArray = true;
      }
    }else{
      throw new ParseException();
    }
  }
  String getNameString(){
    Name nt = (Name)(children.get(0));
    return nt.name;
  }
  int getIndex(int k, Environment e){
    if(isArray){
      Object index = ((Expr)(children.get(1))).eval(k+1, e);
      return (Integer)index;
    }else{
      throw new RuntimeException();
    }
  }
  Object eval(int k, Environment e){
    if(isFunccall){
      Function fun = (Function)(e.get(getNameString()));
      if(children.size()==2) return fun.call((Arguments)(children.get(1)), k+1, e);
      else return fun.call(k+1, e);
    }else if(isArray){
      Object[] a = (Object[])(e.get(getNameString()));
      return a[getIndex(k+1, e)];
//      return a.get(getIndex(k+1, e));
    }else{
      return e.get(getNameString());
    }
  }
  void assign(int k, Object x, Environment e){
    if(isArray){  // array
      Object[] a = (Object[])(e.get(getNameString()));
      a[getIndex(k+1, e)] = x;
    }else if(isFunccall){
      throw new AssignmentException();
    }else{ // variable
      e.put(getNameString(), x);
    }
  }
}

// Statement ::= Reserved | Expr | Assign
class Statement extends ASTList{
  boolean isAssign=false;
  Statement(TokenList tl){
    if(tl.isReserved()){
      Name rn = tl.readReserved();
      if(rn.name.equals("if")){
        children.add(new If(tl));
      }else if(rn.name.equals("while")){
        children.add(new While(tl));
      }else if(rn.name.equals("new")){
        children.add(new Array1DDef(tl));
      }else if(rn.name.equals("def")){
        children.add(new FuncDef(tl));
      }else if(rn.name.equals("print")){
        children.add(new Print(tl));
      }else if(rn.name.equals("add")){
        children.add(new AddDraw(tl));
      }
    }else{
      children.add(new Expr(tl));
      if(tl.isOperator("=")){
        tl.readOperator("=");
        children.add(new Expr(tl));
        isAssign = true;
      }
    }
  }
  Object eval(int k, Environment e){
    if(isAssign){
      Expr s = (Expr)(children.get(0));
      Val v = (Val)(s.children.get(0));
      NamedElement ne = (NamedElement)(v.children.get(0));
      Object right = children.get(1).eval(k+1, e);
      ne.assign(k+1, right, e);
      return right;
    }else{
      return children.get(0).eval(k+1, e);
    }
  }
}

// Program ::= Statement { ";" [Statement] }
class Program extends ASTList{
  Program(TokenList tl){
    children.add(new Statement(tl));
    while(tl.isOperator(";")){
      tl.readOperator(";");
      try{
        children.add(new Statement(tl));
      }catch(Exception e){
      }
    }
  }
  Object eval(int k, Environment e){
    Object ret = null;
    for(AST a: children){
      ret = a.eval(k+1, e);
    }
    return ret;
  }
}

// parameters ::= Name { "," Name }
class Parameters extends ASTList{
  Parameters(TokenList tl){
    children.add(tl.readName());
    while(tl.isOperator(",")){
      tl.readOperator(",");
      children.add(tl.readName());
    }
  }
  Object eval(int k, Environment e){
    return null;
  }
}

// arguments ::= Expr { "," Expr }
class Arguments extends ASTList{
  Arguments(TokenList tl){
    children.add(new Expr(tl));
    while(tl.isOperator(",")){
      tl.readOperator(",");
      children.add(new Expr(tl));
    }
  }
  Object eval(int k, Environment e){
    return null;
  }
}

// Array1DDef ::= "new" Array1D
class Array1DDef extends ASTList{
  Array1DDef(TokenList tl){
    NamedElement a = new NamedElement(tl);
    if(a.isArray){
      children.add(a);
    }else{
      throw new ParseException();
    }
  }
  Object eval(int k, Environment e){
    NamedElement a = (NamedElement)(children.get(0));
    Object[] array = new Object[a.getIndex(k+1, e)];
    e.put(a.getNameString(), array);
    return array;
  }
}

class Draw extends ASTList{
  Object eval(int k, Environment e){
    Object ret = null;
    for(AST a: children){
      ret = a.eval(k+1, e);
    }
    return ret;
  }
}

class AddDraw extends ASTList{
  AddDraw(TokenList tl){
    NamedElement a = new NamedElement(tl);
    children.add(a);
  }
  Object eval(int k, Environment e){
    NamedElement fn = (NamedElement)(children.get(0));
    fn.isFunccall=true;
    ((Draw)(e.get("draw"))).children.add(fn);
    return null;
  }
}
  
