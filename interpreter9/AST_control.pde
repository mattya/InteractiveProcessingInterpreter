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
