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
