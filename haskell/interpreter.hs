-- 関数の導入

import Text.Regex.TDFA
import qualified Data.Map as M
import Control.Monad
import Data.Maybe

interpreter :: String -> Object
interpreter str = fst $ runTransition (eval . fst . parseProgram $ tokenizer str) $ [M.empty]

data Token = ReservedToken String | BinaryOperatorToken String | OperatorToken String | NumberToken Double | StringToken String | NamedToken String deriving Show

regex = "(if|while|def)|(&&|\\|\\||>|>=|<|<=|==|!=|[+*-])|([\\(\\)=;{}])|([0-9]+\\.?[0-9]*)|'(.*)'|([a-zA-Z]+)"
tokenizer :: String -> [Token]
tokenizer s =
	let
		mattya = s =~ regex :: [[String]]
	in map tokenize mattya

tokenize :: [String]->Token
tokenize (_:s:"":"":"":"":"":[]) = ReservedToken s
tokenize (_:"":s:"":"":"":"":[]) = BinaryOperatorToken s
tokenize (_:"":"":s:"":"":"":[]) = OperatorToken s
tokenize (_:"":"":"":s:"":"":[]) = NumberToken $ read s
tokenize (_:"":"":"":"":s:"":[]) = StringToken s
tokenize (_:"":"":"":"":"":s:[]) = NamedToken s

type Env = [M.Map String Object]
getEnv :: String->Env->Maybe Object
getEnv key ms = foldr mplus Nothing $ map (M.lookup key) ms

updateEnv :: String->Object->Env->Env
updateEnv key o mall@(m:ms) = if all (M.notMember key) mall
	then (M.insert key o m):ms
	else updateEnv' key o mall where
		updateEnv' :: String->Object->Env->Env
		updateEnv' key o (m:ms) = if M.member key m
			then (M.insert key o m):ms
			else m:(updateEnv' key o ms)

addEnv :: String->Object->Env->Env
addEnv key o (m:ms) = (M.insert key o m):ms

data Object = Null | Double Double | Int Int | String String | Bool Bool | AST AST deriving (Show, Eq)

type Name = String
type Cond = AST
type Statement = AST
type Params = [String]
type Args = [AST]
data AST= Value Object
        | Operator BinaryOperator AST AST
        | Assign Name AST
        | Variable Name
        | FuncDef Name Params AST
        | FuncCall Name Args
        | Program [AST]
        | If Cond AST
        | While Cond AST
instance Show AST where
	show (Value x) = show x
	show (Operator _ l r) = "("++(show l)++")op("++(show r)++")"
	show (Assign n r) = n++" = "++(show r)
	show (Variable n) = "Variable: "++n
	show (FuncDef fn param prog) = fn++(show param)++" {"++(show prog)++"}"
	show (FuncCall fn args) = fn++(show args)
	show (Program prog) = "Program: "++(show prog)
	show (If cond prog) = "if "++(show cond)++" {"++(show prog)++"}"
	show (While cond prog) = "while "++(show cond)++" {"++(show prog)++"}"
instance Eq AST where
	_==_ = False

-- Program ::= Statement | Statement ";" Program
parseProgram :: [Token] -> (AST, [Token])
parseProgram [] = (Program [], [])
parseProgram ts@((OperatorToken "}"):_) = (Program [], ts)
parseProgram ((OperatorToken ";"):ts) = parseProgram ts
parseProgram ts =
	let (left, ts0) = parseStatement ts
	in case ts0 of
		[] -> (Program [left], ts0)
		ts@((OperatorToken "}"):_) -> (Program [left], ts)
		otherwise -> let (right, ts1) = parseProgram ts0
				in (Program (left:[right]), ts1)

-- Statement ::= BinaryExpr | AssignExpr | IfStmnt | WhileStmnt | FuncDef
parseStatement :: [Token] -> (AST, [Token])
parseStatement ts0@((NamedToken v):(OperatorToken "="):ts) = parseAssign ts0
parseStatement ((ReservedToken "if"):ts) = parseIfStmnt ts
parseStatement ((ReservedToken "while"):ts) = parseWhileStmnt ts
parseStatement ((ReservedToken "def"):ts) = parseFuncDef ts
parseStatement ts = parseBinaryExpr ts

-- FuncDef ::= "def" FuncName "(" Parameters ")" {" Program "}"
parseFuncDef :: [Token] -> (AST, [Token])
parseFuncDef ((NamedToken fn):(OperatorToken "("):ts) =
	let (params, ts0) = parseParameters ts in case ts0 of
		(OperatorToken ")"):(OperatorToken "{"):ts1 -> let (prog, ts2) = parseProgram ts1 in case ts2 of
			(OperatorToken "}"):ts3 -> (FuncDef fn params prog, ts3)
			otherwise -> parseError "missing } in FuncDef" ts2
		otherwise -> parseError "missing { in FuncDef" ts0

-- Parameters ::= Variable | Variable "," Parameters
parseParameters :: [Token] -> ([String], [Token])
parseParameters ((NamedToken p):(OperatorToken ","):ts) =
	let (right, ts0) = parseParameters ts in (p:right, ts0)
parseParameters ((NamedToken p):ts) = ([p], ts)
parseParameters ts = ([], ts)


-- IfStmnt ::= "if" BinaryExpr "{" Program "}"
parseIfStmnt :: [Token] -> (AST, [Token])
parseIfStmnt ts =
	let (cond, ts0) = parseBinaryExpr ts in case ts0 of
		(OperatorToken "{"):ts1 -> let (prog, ts2) = parseProgram ts1 in case ts2 of
			(OperatorToken "}"):ts3 -> (If cond prog, ts3)
			otherwise -> parseError "missing } in IfStmnt" ts2
		otherwise -> parseError "missing { in IfStmnt" ts0

-- WhileStmnt ::= "while" BinaryExpr "{" Program "}"
parseWhileStmnt :: [Token] -> (AST, [Token])
parseWhileStmnt ts =
	let (cond, ts0) = parseBinaryExpr ts in case ts0 of
		(OperatorToken "{"):ts1 -> let (prog, ts2) = parseProgram ts1 in case ts2 of
			(OperatorToken "}"):ts3 -> (While cond prog, ts3)
			otherwise -> parseError "missing } in WhileStmnt" ts2
		otherwise -> parseError "missing { in WhileStmnt" ts0

-- AssignExpr ::= Variable "=" Statement
parseAssign :: [Token] -> (AST, [Token])
parseAssign ((NamedToken key):(OperatorToken "="):ts) =
	let (right, ts0) = parseStatement ts
	in (Assign key right, ts0)


type BinaryOperator = ((Object->Object->Object), Int)
data BinaryExpr = BinaryExprRight AST | BinaryExprLeft AST BinaryOperator BinaryExpr

-- BinaryExpr ::= PrimaryExpr | PrimaryExpr Op BinaryExpr
parseBinaryExpr :: [Token] -> (AST, [Token])
parseBinaryExpr ts = let (b, ts0) = parseBinaryExpr1 ts in ((parseBinaryExpr2 b), ts0) where
	parseBinaryExpr1 :: [Token] -> (BinaryExpr, [Token])
	parseBinaryExpr1 ts = let
			(left, ts0) = parsePrimaryExpr ts
			op = parseBinaryOperator ts0
		in case op of
			Nothing -> (BinaryExprRight left, ts0)
			Just bop ->
				let (right, ts1) = parseBinaryExpr1 (tail ts0) in
				(BinaryExprLeft left bop right, ts1)

	parseBinaryExpr2 :: BinaryExpr -> AST
	parseBinaryExpr2 (BinaryExprRight expr) = expr
	parseBinaryExpr2 (BinaryExprLeft left op right) =
		case right of
			BinaryExprRight expr -> (Operator op left expr)
			BinaryExprLeft mid op2 right2 ->
				if (snd op) < (snd op2)
					then (Operator op left (Operator op2 mid (parseBinaryExpr2 right2)))
					else (Operator op (Operator op left mid)  (parseBinaryExpr2 right2))

	parseBinaryOperator :: [Token] -> Maybe BinaryOperator
	parseBinaryOperator [] = Nothing
	parseBinaryOperator ((BinaryOperatorToken "&&"):_) =
		Just (f, 10) where f (Bool x) (Bool y) = Bool $ x&&y
	parseBinaryOperator ((BinaryOperatorToken "||"):_) =
		Just (f, 10) where f (Bool x) (Bool y) = Bool $ x||y
	parseBinaryOperator ((BinaryOperatorToken "<"):_) =
		Just (f, 20) where f (Double x) (Double y) = Bool $ x<y
	parseBinaryOperator ((BinaryOperatorToken "<="):_) =
		Just (f, 20) where f (Double x) (Double y) = Bool $ x<=y
	parseBinaryOperator ((BinaryOperatorToken ">"):_) =
		Just (f, 20) where f (Double x) (Double y) = Bool $ x>y
	parseBinaryOperator ((BinaryOperatorToken ">="):_) =
		Just (f, 20) where f (Double x) (Double y) = Bool $ x>=y
	parseBinaryOperator ((BinaryOperatorToken "=="):_) =
		Just (f, 20) where f (Double x) (Double y) = Bool $ x==y
	parseBinaryOperator ((BinaryOperatorToken "!="):_) =
		Just (f, 20) where f (Double x) (Double y) = Bool $ x/=y
	parseBinaryOperator ((BinaryOperatorToken "+"):_) =
		Just (f, 30) where
			f (Double x) (Double y) = Double $ x+y
			f (String x) (String y) = String $ x++y
	parseBinaryOperator ((BinaryOperatorToken "-"):_) =
		Just (f, 30) where f (Double x) (Double y) = Double $ x-y
	parseBinaryOperator ((BinaryOperatorToken "*"):_) =
		Just (f, 40) where
			f (Double x) (Double y) = Double $ x*y
	parseBinaryOperator _ = Nothing

-- Primary ::= (BinaryExpr) | Object | FuncCall | Variable
parsePrimaryExpr :: [Token] -> (AST, [Token])
parsePrimaryExpr ((OperatorToken "("):ts) =
	let (ast, ts0) = parseBinaryExpr ts in case ts0 of
		[] -> parseError "missing ')'?" ts
		(OperatorToken ")"):ts1 -> (ast, ts1)
		otherwise -> parseError "invalid primaryExpr" ts
parsePrimaryExpr (NamedToken v:ts) = case ts of
-- FuncCall
	(OperatorToken "("):ts0 -> let (args, ts1) = parseArguments ts0 in case ts1 of
		(OperatorToken ")"):ts2 -> (FuncCall v args, ts2)
		otherwise -> parseError "invalid FuncCall" ts1
-- Variable
	otherwise -> (Variable v, ts)
parsePrimaryExpr ((NumberToken x):ts) = ((Value $ Double x), ts)
parsePrimaryExpr ((StringToken x):ts) = ((Value $ String x), ts)

-- Arguments ::= Primary | Primary "," Arguments
parseArguments :: [Token] -> ([AST], [Token])
parseArguments ts =
	let (left, ts0) = parseStatement ts
	in case ts0 of
		(OperatorToken ","):ts1 -> let (right, ts2) = parseArguments ts1 in (left:right, ts2)
		otherwise -> ([left], ts0)

parseError :: String -> [Token] -> a
parseError msg ts = error $ "Parse Error: " ++ msg ++ (concat $ map (("\n"++).show) ts)

newtype StateTransition s a = StateTransition{runTransition::(s -> (a, s))}
instance Monad (StateTransition s) where
	return x = StateTransition (\t -> (x, t))
	(StateTransition h) >>= f = StateTransition (\t -> let
								(a, nt) = h t
								StateTransition g = f a
							in g nt)
	-- hで遷移して、出てきたaにfを作用すると次の遷移gが得られるので、それでも遷移する
endTransition = StateTransition (\e -> (Null, e))

eval :: AST -> (StateTransition Env Object)
eval (Program xs) = foldl (>>) (return Null) (map eval xs)
--eval (Program xs) = let () map eval xs
eval (Value x) = return x
eval (Operator op lhs rhs) = do
	a <- eval lhs
	b <- eval rhs
	return $ (fst op) a b
eval (Assign n rhs) = do
	a <- eval rhs
	StateTransition $ \e -> (a, updateEnv n a e)
eval (Variable v) =
	StateTransition $ \e -> (fromJust $ getEnv v e, e)
eval f@(FuncDef fn params prog) =
	StateTransition $ \e -> ((AST f), updateEnv fn (AST f) e)
eval (FuncCall fn args) = do
	objs <- StateTransition (\e -> foldf e $ map eval args)
	(AST (FuncDef _ params prog)) <- eval (Variable fn)

	StateTransition (\e -> (Null, (M.empty):e)) -- inner Env
	foldl (>>) (return Null) $ map (\(p, o) -> StateTransition (\e->(o, addEnv p o e))) $ zip params objs
	ret <- eval prog
--	return ret
	StateTransition (\(e:es) -> (ret, es)) -- outer Env

eval (If cond prog) = do
	a <- eval cond
	if a==(Bool True)
		then eval prog
		else endTransition
eval (While cond prog) = do loop cond prog where
	loop c p = do
		a <- eval c
		if a==(Bool True)
			then do
				eval p
				loop c p
			else endTransition

foldf :: Env -> [StateTransition Env Object] -> ([Object], Env)
foldf e ((StateTransition{runTransition=r}):[]) = let (o, ne) = r e in ([o], ne)
foldf e ((StateTransition{runTransition=r}):ss) = (o:os, nne) where
	(o, ne) = r e
	(os, nne) = foldf ne ss

