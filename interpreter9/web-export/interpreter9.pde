// Expr ::= Val { BinaryOperator Val }
// Val ::= '(' Expr ')' | Number | NamedElement
// NamedElement ::= Name [ "(" Arguments ")" | "[" Expr "]" ]
// Statement ::= Reserved | Expr | Assign
// Program ::= Statement { ";" [Statement] }
// parameters ::= Name { "," Name }
// Array1DDef ::= "new" Array1D
// arguments ::= Expr { "," Expr }
// while ::= "while" condition "{" program "}"
// if ::= "if" condition "{" program "}" [ "else" "{" program "}" ]
// funcdef ::= "def" Name "(" parameters ")" "{" program "}"

// BinaryOperator
// level  op
// 0 * / %
// 1 + -
// 2 < <= > >=
// 3 == !=
// 4 && ||



import java.awt.*;

TextField tf = new TextField(40); 

Environment e;
String s = "";
int line=0;

void setup(){
  size(500, 500);
  add(tf);
  e = new Environment(null);
  background(255);
  addLibraryFunctions(e);
  e.put("draw", new Draw());
}

void draw(){
  if(!s.equals("")){
    fill(0);
    text(s, 20, 50+line*15);
    line++;
    
    Token[] ls = tokenizer(s);
    for(Token l: ls){
      l.print();
    }
    TokenList tl = new TokenList(ls);
    AST ast = null;
    try{
      ast = new Program(tl);
      try{
        ast.eval(0, e);
      }catch(Exception e){
        println("Runtime eror");
        println(e);
      }
    }catch(Exception e){
      println("Parse error");
    }
    s="";
  }
  ((Draw)(e.get("draw"))).eval(0, e);
}

void mousePressed(){
  s = tf.getText();
}
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
  
// while ::= "while" Expr "{" program "}"
class While extends ASTList{
  While(TokenList tl){
    children.add(new Expr(tl));
    tl.readOperator("{");
    children.add(new Program(tl));
    tl.readOperator("}");
  }
  Object eval(int k, Environment e){
    Object ret = null;
    while((Boolean)(((Expr)children.get(0)).eval(k+1, e))){
      ret = ((Program)children.get(1)).eval(k+1, e);
    }
    return ret;
  }
}

// if ::= "if" Expr "{" program "}" [ "else" "{" program "}" ]
class If extends ASTList{
  If(TokenList tl){
    children.add(new Expr(tl));
    tl.readOperator("{");
    children.add(new Program(tl));
    tl.readOperator("}");
    if(tl.isReserved("else")){
      tl.readReserved("else");
      tl.readOperator("{");
      children.add(new Program(tl));
      tl.readOperator("}");
    }
  }
  Object eval(int k, Environment e){
    Object ret = null;
    boolean cond = (Boolean)((Expr)(children.get(0))).eval(k+1, e);
    if(cond){
      ret = ((Program)children.get(1)).eval(k+1, e);
    }else{
      if(children.get(2)!=null){
        ret = ((Program)children.get(2)).eval(k+1, e);
      }
    }
    return ret;
  }
}

// funcdef ::= "def" Name "(" [parameters] ")" "{" program "}"
class FuncDef extends ASTList{
  FuncDef(TokenList tl){
    children.add(tl.readName());
    tl.readOperator("(");
    if(!tl.isOperator(")")) children.add(new Parameters(tl));
    tl.readOperator(")");
    tl.readOperator("{");
    children.add(new Program(tl));
    tl.readOperator("}");
  }
  Object eval(int k, Environment e){
  // 定義した関数を表すFunctionクラスのインスタンスを作り、
    Function func;
    if(children.size()==3) func = new Function((Parameters)(children.get(1)), (Program)(children.get(2)));
    else func = new Function(null, (Program)(children.get(1)));
  // 関数名とそのインスタンスの組を環境に登録する
    e.put(((Name)(children.get(0))).name, func);
    return 0;
  }
}

// Print ::= "print" Arguments
class Print extends ASTList{
  Print(TokenList tl){
    children.add(new Arguments(tl));
  }
  Object eval(int k, Environment e){
    print("Print: ");
    Arguments arg = (Arguments)(children.get(0));
    for(int i=0; i<arg.children.size(); i++){
      print(arg.children.get(i).eval(k+1, e) + ", ");
    }
    println();
    return null;
  }
}

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
class Environment{
  HashMap<String, Object> hm;   // 変数でなく関数も記録できるように<String, Object>に
  Environment outer;            // 外側の環境を指す
  Environment(Environment eo){
    hm = new HashMap<String, Object>();
    outer = eo;
  }
  // 変数or関数名strが存在するかを調べる。この環境内になかったら外側も調べる。
  boolean find(String str){
    if(hm.containsKey(str)) return true;
    else if(outer==null) return false;
    else return outer.find(str);
  }
  // strとobjの組を記録する。同じ名前がすでに存在していたら(外側の環境でも)、それを上書きする。
  void put(String str, Object obj){
    if(find(str)){
      if(hm.containsKey(str)) hm.put(str, obj);
      else outer.put(str, obj);   // 外側にstrが存在している時。外側のput命令を呼び出す。
    }else{
      hm.put(str, obj);
    }
  }
  // strとobjの組を記録する。外側に同名の変数があったとしても気にせず、この環境内に記録する。
  void put_new(String str, Object obj){
    hm.put(str, obj);
  }
  // 名前strの中身を取得
  Object get(String str){
    if(hm.containsKey(str)) return hm.get(str);
    else if(outer==null) return null;
    else return outer.get(str);
  }
}



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
class Token{
  void print(){}
}

class NumberToken extends Token{
  int num;
  NumberToken(int n0){ num = n0; }
  void print(){
    println(num + " : NumberToken");
  }
}

class BinaryOperatorToken extends Token{
  String op;
  BinaryOperatorToken(String s0){ op = s0; }
  void print(){
    println(op + " : BinaryOperatorToken");
  }
}


class OperatorToken extends Token{
  String op;
  OperatorToken(String s0){ op = s0; }
  void print(){
    println(op + " : OperatorToken");
  }
}


class ReservedNameToken extends Token{
  String name;
  ReservedNameToken(String n0){ name = n0; }
  void print(){
    println(name + " : ReservedNameToken");
  }
}


class NameToken extends Token{
  String name;
  NameToken(String n0){ name = n0; }
  void print(){
    println(name + " : NameToken");
  }
}

class Function{
  Parameters p;
  Program prog;
  Function(){
  }
  Function(Parameters p0, Program prog0){
    p = p0;
    prog = prog0;
  }
  Object call(int k, Environment e){
    Environment ne = new Environment(e);
    return prog.eval(k+1, ne);
  }
  Object call(Arguments args, int k, Environment e){
    // 新しい環境neを現在の環境eの内側につくる
    Environment ne = new Environment(e);
    for(int i=0; i<args.children.size(); i++){
    //   neに、引数の名前(Functionオブジェクトのpに記録されている)と
    //   その中身(args)のペアを1つずつ追加していく
      String paramname = ((Name)(p.children.get(i))).name;
      Object paramval = args.children.get(i).eval(k+1, e);
      if(DEBUG) println(paramname+" : "+paramval);
      ne.put_new(paramname, paramval);
    }
    // 関数の処理(Functionオブジェクトのprog)を、新しい環境neのもとで実行する
    return prog.eval(k+1, ne);
  }
}


class Array1D{
  Object get(int index){
    return null;
  }
  void put(int index, Object x){
    
  }
}

boolean DEBUG = false;

class TokenList{
  Token[] tokens;
  int p;
  TokenList(Token[] ts){
    tokens = ts;
    p=0;
  }
  
  boolean isName(){
    if(p>=tokens.length) return false;
    return tokens[p] instanceof NameToken;
  }
  boolean isOperator(){
    if(p>=tokens.length) return false;
    return tokens[p] instanceof OperatorToken;
  }
  boolean isOperator(String str){
    if(p>=tokens.length) return false;
    if(tokens[p] instanceof OperatorToken){
      OperatorToken opt = (OperatorToken)tokens[p];
      return opt.op.equals(str);
    }
    return false;
  }
  boolean isNumber(){
    if(p>=tokens.length) return false;
    return tokens[p] instanceof NumberToken;
  }
  boolean isReserved(){
    if(p>=tokens.length) return false;
    return tokens[p] instanceof ReservedNameToken;
  }
  boolean isReserved(String str){
    if(p>=tokens.length) return false;
    if(tokens[p] instanceof ReservedNameToken){
      ReservedNameToken rnt = (ReservedNameToken)tokens[p];
      return rnt.name.equals(str);
    }
    return false;
  }
  boolean isBinaryOperator(){
    if(p>=tokens.length) return false;
    return tokens[p] instanceof BinaryOperatorToken;
  }
  Name readName(){
    if(DEBUG){ print("read "+p+", "); tokens[p].print(); }
    NameToken nt = (NameToken)tokens[p++];
    return new Name(nt.name);
  }
  void readOperator(String str){
    if(DEBUG){ print("read "+p+", "); tokens[p].print(); }
    OperatorToken opt = (OperatorToken)tokens[p++];
    if(!opt.op.equals(str)) throw new ParseException();
  }
  BinaryOperator readBinaryOperator(){
    if(DEBUG){ print("read "+p+", "); tokens[p].print(); }
    BinaryOperatorToken bot = (BinaryOperatorToken)tokens[p++];
    String op = bot.op;
    if(op.equals("*")) return new MultOp();
    else if(op.equals("/")) return new DivOp();
    else if(op.equals("%")) return new ModOp();
    else if(op.equals("+")) return new PlusOp();
    else if(op.equals("-")) return new MinusOp();
    else if(op.equals("<")) return new LTOp();
    else if(op.equals("<=")) return new LTEOp();
    else if(op.equals(">")) return new GTOp();
    else if(op.equals(">=")) return new GTEOp();
    else if(op.equals("==")) return new EqOp();
    else if(op.equals("!=")) return new NEqOp();
    else if(op.equals("&&")) return new AndOp();
    else if(op.equals("||")) return new OrOp();
//    if(op.equals("/")) return new DivOp();
//    if(op.equals("/")) return new DivOp();
//    return new BinaryOperator(((BinaryOperatorToken)tokens[p++]).op);
    throw new ParseException();
  }
  void readBinaryOperator(String str){
    if(DEBUG){ print("read "+p+", "); tokens[p].print(); }
    BinaryOperatorToken bot = (BinaryOperatorToken)tokens[p++];
    if(!(bot.op.equals(str))) throw new ParseException();
  }
  Number readNumber(){
    if(DEBUG){ print("read "+p+", "); tokens[p].print(); }
    NumberToken nt = (NumberToken)tokens[p++];
    return new Number(nt.num);
  }
  Name readReserved(){
    if(DEBUG){ print("read "+p+", "); tokens[p].print(); }
    ReservedNameToken rnt = (ReservedNameToken)tokens[p++];
    return new Name(rnt.name);
  }
  void readReserved(String str){
    if(DEBUG){ print("read "+p+", "); tokens[p].print(); }
    ReservedNameToken rnt = (ReservedNameToken)tokens[p++];
    if(!rnt.name.equals(str)) throw new ParseException();
  }
}

Token[] tokenizer(String s){
  String[][] m = matchAll(s, "\\s*((if|else|while|new|def|print|add)|([0-9]+)|(\\|\\||&&|==|!=|>=|<=|[><+*\\-/%])|([\\[\\],;=\\(\\){}])|([a-zA-Z]+))\\s*");
  Token[] ret = new Token[m.length];
  for(int i=0; i<m.length; i++){
    if(m[i][2]!=null) ret[i] = new ReservedNameToken(m[i][2]);
    else if(m[i][3]!=null) ret[i] = new NumberToken(int(m[i][3]));
    else if(m[i][4]!=null) ret[i] = new BinaryOperatorToken(m[i][4]);
    else if(m[i][5]!=null) ret[i] = new OperatorToken(m[i][5]);
    else if(m[i][6]!=null) ret[i] = new NameToken(m[i][6]);
  }
  return ret;
}

public class ParseException extends RuntimeException {
  public ParseException(){
    super();
  }
}
public class AssignmentException extends RuntimeException {
  public AssignmentException(){
    super();
  }
}

