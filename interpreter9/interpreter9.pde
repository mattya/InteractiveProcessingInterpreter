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
