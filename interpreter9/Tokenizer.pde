
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
