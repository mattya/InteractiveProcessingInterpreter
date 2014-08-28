
Environment e;
int line=0;

var query_string="";
void get_string(){
  query_string=document.getElementById("program").value;
}

void setup(){
  size(500, 500);
  e = new Environment(null);
  background(255);
}

void draw(){
  if(!query_string.equals("")){
    fill(0);
    text(query_string, 20, 50+line*15);
    line++;

    Token[] ls = tokenizer(query_string);
    AST ast = new Program(ls, 0);
    println(ast.eval(0, e));
    query_string="";
  }
}


class AST{
  int num_token = 0;
  boolean ok = false;
  int eval(int k, Environment e){return 0;}
}

class ASTList extends AST{
  ArrayList<AST> children;
  ASTList(){
    children = new ArrayList<AST>();
  }
}

class ASTLeaf extends AST{
  Token child;
  ASTLeaf(){ }
  ASTLeaf(Token l0){
    child = l0;
  }
}

// Num ::= '(' Sum ')' | NumberLiteral | funccall | array | variable
class Num extends ASTList{
  Num(Token[] ls, int p){
    println("Num " + p);
    if(ls[p] instanceof OperatorToken){
      if(!((OperatorToken)ls[p]).op.equals("(")) return;
      AST s = new Sum(ls, p+1);
      if(s.ok==false) return;
      if(p+s.num_token+1>=ls.length) return;
      if(!(ls[p+s.num_token+1] instanceof OperatorToken)) return;
      if(!((OperatorToken)ls[p+s.num_token+1]).op.equals(")")) return;
      num_token = 1+s.num_token+1;
      children.add(s);
      ok = true;
    }else if(ls[p] instanceof NumberToken){
      children.add(new ASTLeaf(ls[p]));
      num_token=1;
      ok = true;
    }else if(ls[p] instanceof NameToken){
      AST funccall = new FuncCall(ls, p);
      if(funccall.ok==true){
        children.add(funccall);
        num_token = funccall.num_token;
        ok = true;
        return;
      }
      AST array = new Array1D(ls, p);
      if(array.ok==true){
        children.add(array);
        num_token = array.num_token;
        ok = true;
        return;
      }
      children.add(new Variable(((NameToken)ls[p]).name));
      num_token=1;
      ok = true;
    }
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("Num");
    if(children.get(0) instanceof Sum
       || children.get(0) instanceof Variable
       || children.get(0) instanceof FuncCall
       || children.get(0) instanceof Array1D)
      return children.get(0).eval(k+1, e);
    else return ((NumberToken)((ASTLeaf)children.get(0)).child).num;
  }
}


class Variable extends ASTLeaf{
  String name;
  Variable(String n0){
    name = n0;
    num_token = 1;
  }
  int eval(int k, Environment e){
    return (Integer)e.get(name);
  }
}


// Statement ::= Assign | While | If | FuncDef | ArrayDef | ArrayAssign | print | Sum
class Statement extends ASTList{
  Statement(Token[] ls, int p){
    println("Statement " + p);
    AST s = new Assign(ls, p);
    if(s.ok==false){
      s = new While(ls, p);
    }
    if(s.ok==false){
      s = new If(ls, p);
    }
    if(s.ok==false){
      s = new FuncDef(ls, p);
    }
    if(s.ok==false){
      s = new Array1DDef(ls, p);
    }
    if(s.ok==false){
      s = new Array1DAssign(ls, p);
    }
    if(s.ok==false){
      s = new Print(ls, p);
    }
    if(s.ok==false){
      s = new Sum(ls, p);
    }
    if(s.ok==false) return;
    children.add(s);
    num_token = s.num_token;
    ok=true;
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("Statement");
    return children.get(0).eval(k+1, e);
  }
}

// Program ::= Statement { ";" [Statement] }
class Program extends ASTList{
  Program(Token[] ls, int p){
    println("Program " + p);
    AST s = new Statement(ls, p);
    if(s.ok==false) return;
    children.add(s);
    num_token = s.num_token;
    while(p+num_token+1<ls.length){
      if(!(ls[p+num_token] instanceof OperatorToken)) break;
      if(!((OperatorToken)ls[p+num_token]).op.equals(";")) break;
      num_token += 1;

      s = new Statement(ls, p+num_token);
      if(s.ok==true){
        children.add(s);
        num_token += s.num_token;
      }
    }
    ok=true;
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("Program");
    int ret = 0;
    for(AST a: children){
      ret = a.eval(k+1, e);
    }
    return ret;
  }
}

// parameters ::= name { "," name }
class Parameters extends ASTList{
  Parameters(Token[] ls, int p){
    println("Parameters " + p);
    if(!(ls[p] instanceof NameToken)) return;
    children.add(new ASTLeaf(ls[p]));
    num_token = 1;
    while(p+num_token+1<ls.length){
      if(!(ls[p+num_token] instanceof OperatorToken)) break;
      if(!((OperatorToken)ls[p+num_token]).op.equals(",")) break;

      if(!(ls[p+num_token+1] instanceof NameToken)) return;
      children.add(new ASTLeaf(ls[p+num_token+1]));
      num_token += 2;
    }
    ok=true;
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("Parameters");
    int ret = 0;
    return ret;
  }
}

// arguments ::= sum { "," sum }
class Arguments extends ASTList{
  Arguments(Token[] ls, int p){
    println("Arguments " + p);
    AST s = new Sum(ls, p);
    if(s.ok==false) return;
    children.add(s);
    num_token = s.num_token;
    while(p+num_token+1<ls.length){
      if(!(ls[p+num_token] instanceof OperatorToken)) break;
      if(!((OperatorToken)ls[p+num_token]).op.equals(",")) break;
      num_token += 1;

      s = new Sum(ls, p+num_token);
      if(s.ok==true){
        children.add(s);
        num_token += s.num_token;
      }
    }
    ok=true;
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("Arguments");
    int ret = 0;
    return ret;
  }
}

// Print ::= "print" Arguments
class Print extends ASTList{
  Print(Token[] ls, int p){
    println("Print " + p);
    if(!(ls[p] instanceof NameToken)) return;
    if(!((NameToken)ls[p]).name.equals("print")) return;

    AST s = new Arguments(ls, p+1);
    if(s.ok==false) return;
    children.add(s);
    num_token = s.num_token+1;
    ok=true;
  }
  int eval(int k, Environment e){
    print("Print: ");
    Arguments arg = (Arguments)(children.get(0));
    for(int i=0; i<arg.children.size(); i++){
      print(arg.children.get(i).eval(k+1, e) + ", ");
    }
    println();
    return 0;
  }
}

// Array1D ::= NameToken "[" Sum "]"
class Array1D extends ASTList{
  Array1D(Token[] ls, int p){
    println("Array1D " + p);
    if(p+3>=ls.length) return;
    if(!(ls[p] instanceof NameToken)) return;
    AST array_name = new ASTLeaf(ls[p]);

    if(!(ls[p+1] instanceof OperatorToken)) return;
    if(!((OperatorToken)ls[p+1]).op.equals("[")) return;
    AST sum = new Sum(ls, p+2);
    if(sum.ok==false) return;
    num_token += 2+sum.num_token;
    if(!(ls[p+num_token] instanceof OperatorToken)) return;
    if(!((OperatorToken)ls[p+num_token]).op.equals("]")) return;
    num_token += 1;
    children.add(array_name);
    children.add(sum);
    ok=true;
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("Array1D");
    String array_name = ((NameToken)(((ASTLeaf)(children.get(0))).child)).name;
    int ind = ((Sum)(children.get(1))).eval(k+1, e);
    int[] a = (int[])(e.get(array_name));
    return a[ind];
  }
}

// Array1DDef ::= "new" Array1D
class Array1DDef extends ASTList{
  Array1DDef(Token[] ls, int p){
    println("Array1DDef " + p);
    if(p+4>=ls.length) return;
    if(!(ls[p] instanceof NameToken)) return;
    if(!((NameToken)ls[p]).name.equals("new")) return;

    AST array = new Array1D(ls, p+1);
    if(array.ok==false) return;
    num_token += 1+array.num_token;
    children.add(array);
    ok=true;
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("Array1DDef");
    Array1D array = (Array1D)(children.get(0));
    String array_name = ((NameToken)(((ASTLeaf)(array.children.get(0))).child)).name;
    int num = ((Sum)(array.children.get(1))).eval(k+1, e);
    e.put(array_name, new int[num]);
    return 0;
  }
}

// Array1DAssign ::= Array1D "=" Sum
class Array1DAssign extends ASTList{
  Array1DAssign(Token[] ls, int p){
    println("Array1DAssign " + p);
    if(p+5>=ls.length) return;
    AST left = new Array1D(ls, p);
    if(left.ok==false) return;
    num_token += left.num_token;
    if(!(ls[p+num_token] instanceof OperatorToken)) return;
    if(!((OperatorToken)ls[p+num_token]).op.equals("=")) return;
    AST right = new Statement(ls, p+num_token+1);
    if(right.ok==false) return;
    children.add(left);
    children.add(right);
    num_token += 1+right.num_token;
    ok=true;
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("Array1DAssign");
    Array1D array = (Array1D)(children.get(0));
    String array_name = ((NameToken)(((ASTLeaf)(array.children.get(0))).child)).name;
    int ind = ((Sum)(array.children.get(1))).eval(k+1, e);
    int[] a = (int [])(e.get(array_name));
    a[ind] = children.get(1).eval(k+1, e);
    return 0;
  }
}
// while ::= "while" condition "{" program "}"
class While extends ASTList{
  While(Token[] ls, int p){
    println("while " + p);
    if(p+5>=ls.length) return;
    if(!(ls[p] instanceof NameToken)) return;
    if(!((NameToken)ls[p]).name.equals("while")) return;
    AST cond = new Condition(ls, p+1);
    if(cond.ok==false) return;
    num_token = 1+cond.num_token;

    if(!(ls[p+num_token] instanceof OperatorToken)) return;
    if(!((OperatorToken)ls[p+num_token]).op.equals("{")) return;
    AST prog = new Program(ls, p+num_token+1);
    if(prog.ok==false) return;
    num_token += 1+prog.num_token;
    if(!(ls[p+num_token] instanceof OperatorToken)) return;
    if(!((OperatorToken)ls[p+num_token]).op.equals("}")) return;
    num_token += 1;
    children.add(cond);
    children.add(prog);
    ok=true;
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("while");
    int ret = 0;
    while(((Condition)children.get(0)).eval(k+1, e)==1){
      ret = ((Program)children.get(1)).eval(k+1, e);
    }
    return ret;
  }
}

// if ::= "if" condition "{" program "}" [ "else" "{" program "}" ]
class If extends ASTList{
  If(Token[] ls, int p){
    println("if " + p);
    if(p+5>=ls.length) return;
    if(!(ls[p] instanceof NameToken)) return;
    if(!((NameToken)ls[p]).name.equals("if")) return;
    AST cond = new Condition(ls, p+1);
    if(cond.ok==false) return;
    num_token = 1+cond.num_token;

    if(!(ls[p+num_token] instanceof OperatorToken)) return;
    if(!((OperatorToken)ls[p+num_token]).op.equals("{")) return;
    AST prog = new Program(ls, p+num_token+1);
    if(prog.ok==false) return;
    num_token += 1+prog.num_token;
    if(!(ls[p+num_token] instanceof OperatorToken)) return;
    if(!((OperatorToken)ls[p+num_token]).op.equals("}")) return;
    num_token++;
    AST prog_else = null;
    while(p+num_token+3<ls.length){
      if(!((NameToken)ls[p+num_token]).name.equals("else")) break;
      if(!(ls[p+num_token+1] instanceof OperatorToken)) break;
      if(!((OperatorToken)ls[p+num_token+1]).op.equals("{")) break;
      prog_else = new Program(ls, p+num_token+2);
      if(prog.ok==false) break;
      num_token += 2+prog_else.num_token;
      if(!(ls[p+num_token] instanceof OperatorToken)) break;
      if(!((OperatorToken)ls[p+num_token]).op.equals("}")) break;
      num_token += 1;
      break;
    }

    children.add(cond);
    children.add(prog);
    children.add(prog_else);
    ok=true;
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("if");
    int ret = 0;
    if(((Condition)children.get(0)).eval(k+1, e)==1){
      ret = ((Program)children.get(1)).eval(k+1, e);
    }else{
      if(children.get(2)!=null){
        ret = ((Program)children.get(2)).eval(k+1, e);
      }
    }
    return ret;
  }
}

// funcdef ::= "def" nametoken "(" parameters ")" "{" program "}"
class FuncDef extends ASTList{
  // コンストラクタはfuncname, params, progを抽出しているだけ
  FuncDef(Token[] ls, int p){
    println("FuncDef " + p);
    if(p+7>=ls.length) return;
    if(!(ls[p] instanceof NameToken)) return;
    if(!((NameToken)ls[p]).name.equals("def")) return;
    if(!(ls[p+1] instanceof NameToken)) return;
    AST funcname = new ASTLeaf(ls[p+1]);

    if(!(ls[p+2] instanceof OperatorToken)) return;
    if(!((OperatorToken)ls[p+2]).op.equals("(")) return;
    AST params = new Parameters(ls, p+3);
    if(params.ok==false){
      if(!(ls[p+3] instanceof OperatorToken)) return;
      if(!((OperatorToken)ls[p+3]).op.equals(")")) return;
      params = null;
      num_token = 4;
    }else{
      if(!(ls[p+3+params.num_token] instanceof OperatorToken)) return;
      if(!((OperatorToken)ls[p+3+params.num_token]).op.equals(")")) return;
      num_token = 4+params.num_token;
    }


    if(!(ls[p+num_token] instanceof OperatorToken)) return;
    if(!((OperatorToken)ls[p+num_token]).op.equals("{")) return;
    AST prog = new Program(ls, p+num_token+1);
    if(prog.ok==false) return;
    num_token += 1+prog.num_token;
    if(!(ls[p+num_token] instanceof OperatorToken)) return;
    if(!((OperatorToken)ls[p+num_token]).op.equals("}")) return;
    num_token += 1;

    children.add(funcname);
    children.add(params);
    children.add(prog);
    ok=true;
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("FuncDef");
  // 定義した関数を表すFunctionクラスのインスタンスを作り、
    Function func = new Function((Parameters)(children.get(1)),
                                 (Program)(children.get(2)));
  // 関数名とそのインスタンスの組を環境に登録する
    e.put(((NameToken)(((ASTLeaf)(children.get(0))).child)).name, func);
    return 0;
  }
}

// funccall ::= name "(" arguments ")"
class FuncCall extends ASTList{
  // 関数名と、引数たちを抽出する。
  FuncCall(Token[] ls, int p){
    println("FuncCall " + p);
    if(p+3>=ls.length) return;
    if(!(ls[p] instanceof NameToken)) return;
    AST funcname = new ASTLeaf(ls[p]);

    if(!(ls[p+1] instanceof OperatorToken)) return;
    if(!((OperatorToken)ls[p+1]).op.equals("(")) return;
    AST args = new Arguments(ls, p+2);
    if(args.ok==false){
      if(!(ls[p+2] instanceof OperatorToken)) return;
      if(!((OperatorToken)ls[p+2]).op.equals(")")) return;
      args = null;
      num_token = 3;
    }else{
      if(!(ls[p+2+args.num_token] instanceof OperatorToken)) return;
      if(!((OperatorToken)ls[p+2+args.num_token]).op.equals(")")) return;
      num_token = 3+args.num_token;
    }

    children.add(funcname);
    children.add(args);
    ok=true;
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("FuncCall");
    // 呼び出された関数のFunctionオブジェクトを環境から取り出す
    NameToken funcname = (NameToken)(((ASTLeaf)(children.get(0))).child);
    Arguments args = (Arguments)(children.get(1));
    Function func = (Function)(e.get(funcname.name));
    // 新しい環境neを現在の環境eの内側につくる
    Environment ne = new Environment(e);
    for(int i=0; i<args.children.size(); i++){
    //   neに、引数の名前(Functionオブジェクトのpに記録されている)と
    //   その中身(args)のペアを1つずつ追加していく
      String paramname = ((NameToken)(((ASTLeaf)(func.p.children.get(i))).child)).name;
      int paramval = args.children.get(i).eval(k+1, e);
      ne.put_new(paramname, paramval);
    }
    // 関数の処理(Functionオブジェクトのprog)を、新しい環境neのもとで実行する
    return func.prog.eval(k+1, ne);
  }
}


// Sum ::= Num {'+' Num | '-' Num }
class Sum extends ASTList{
  Sum(Token[] ls, int p){
    println("Sum " + p);
    AST left = new Num(ls, p);
    if(left.ok==false) return;
    children.add(left);
    num_token = left.num_token;
    while(p+num_token+1 < ls.length){
      if(!(ls[p+num_token] instanceof OperatorToken)) break;
      if(!(((OperatorToken)ls[p+num_token]).op.equals("+")) &&
          (!((OperatorToken)ls[p+num_token]).op.equals("-"))) break;
      AST right = new Num(ls, p+num_token+1);
      if(right.ok==false) break;
      children.add(new ASTLeaf(ls[p+num_token]));
      children.add(right);
      num_token += right.num_token+1;
    }
    ok = true;
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("sum");
    int ret = children.get(0).eval(k+1, e);
    for(int i=1; i<children.size(); i+=2){
//      for(int j=0; j<k; j++) print(" ");
//      ((ASTLeaf)children.get(i)).child.print();
      int right = children.get(i+1).eval(k+1, e);
      if(((OperatorToken)((ASTLeaf)children.get(i)).child).op.equals("+")) ret += right;
      else if(((OperatorToken)((ASTLeaf)children.get(i)).child).op.equals("-")) ret -= right;
    }
    return ret;
  }
}


// Assign :== Variable "=" Statement
class Assign extends ASTList{
  Assign(Token[] ls, int p){
    println("Assign " + p);
    if(p+2>=ls.length) return;
    if(!(ls[p] instanceof NameToken)) return;
    AST left = new Variable(((NameToken)ls[p]).name);
    if(!(ls[p+1] instanceof OperatorToken)) return;
    if(!((OperatorToken)ls[p+1]).op.equals("=")) return;
    AST right = new Statement(ls, p+2);
    if(right.ok==false) return;
    children.add(left);
    children.add(right);
    num_token = 1+1+right.num_token;
    ok=true;
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("Assign");
    int ret = ((Statement)children.get(1)).eval(k+1, e);
    e.put(((Variable)children.get(0)).name, ret);
    return ret;
  }
}

// condition ::= sum ">" sum | sum ">=" sum | sum "==" sum | sum "<=" sum | sum "<" sum
class Condition extends ASTList{
  Condition(Token[] ls, int p){
    println("Condition " + p);
    if(p+2>=ls.length) return;
    AST left = new Sum(ls, p);
    if(left.ok==false) return;
    num_token = left.num_token;
    if(p+num_token+1 >= ls.length) return;
    if(!(ls[p+num_token] instanceof OperatorToken)) return;
    if(!((OperatorToken)ls[p+num_token]).op.equals(">")
        && !((OperatorToken)ls[p+num_token]).op.equals(">=")
        && !((OperatorToken)ls[p+num_token]).op.equals("==")
        && !((OperatorToken)ls[p+num_token]).op.equals("<=")
        && !((OperatorToken)ls[p+num_token]).op.equals("<")) return;
    AST right = new Sum(ls, p+num_token+1);
    if(right.ok==false) return;

    children.add(left);
    children.add(new ASTLeaf(ls[p+num_token]));
    children.add(right);
    num_token += 1+right.num_token;
    ok=true;
  }
  int eval(int k, Environment e){
//    for(int i=0; i<k; i++) print(" ");
//    println("Condition");
    int ret = 0;
    int left = children.get(0).eval(k+1, e);
    int right = children.get(2).eval(k+1, e);
    if(((OperatorToken)((ASTLeaf)children.get(1)).child).op.equals(">")) ret = (left>right?1:0);
    else if(((OperatorToken)((ASTLeaf)children.get(1)).child).op.equals(">=")) ret = (left>=right?1:0);
    else if(((OperatorToken)((ASTLeaf)children.get(1)).child).op.equals("==")) ret = (left==right?1:0);
    else if(((OperatorToken)((ASTLeaf)children.get(1)).child).op.equals("<=")) ret = (left<=right?1:0);
    else if(((OperatorToken)((ASTLeaf)children.get(1)).child).op.equals("<")) ret = (left<right?1:0);
    return ret;
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


class Token{
  int num;
  String op;
  String name;
  void print(){}
}

class NumberToken extends Token{
  NumberToken(int n0){ num = n0; }
  void print(){
    println(num + " : NumberToken");
  }
}

class OperatorToken extends Token{
  OperatorToken(String s0){ op = s0; }
  void print(){
    println(op + " : OperatorToken");
  }
}



class NameToken extends Token{
  NameToken(String n0){ name = n0; }
  void print(){
    println(name + " : NameToken");
  }
}

class Function{
  Parameters p;
  Program prog;
  Function(Parameters p0, Program prog0){
    p = p0;
    prog = prog0;
  }
}



Token[] tokenizer(String s){
  String[][] m = matchAll(s, "\\s*(([0-9]+)|(==|>=|<=|[\\[\\],><;=+*\\-/\\(\\){}])|([a-zA-Z]+))\\s*");
  Token[] ret = new Token[m.length];
  for(int i=0; i<m.length; i++){
    if(m[i][2]!=null) ret[i] = new NumberToken(int(m[i][2]));
    else if(m[i][3]!=null) ret[i] = new OperatorToken(m[i][3]);
    else if(m[i][4]!=null) ret[i] = new NameToken(m[i][4]);
  }
  return ret;
}

