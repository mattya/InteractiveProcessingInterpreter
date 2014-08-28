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


