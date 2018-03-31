{-# LANGUAGE LambdaCase        #-}
{-# LANGUAGE OverloadedStrings #-}
module Type where

import qualified Data.Map        as M
import           Data.Text       (Text)
import           Data.Void
import qualified LLVM.AST.Type   as T
import qualified LLVM.AST.Typed  as T
import           Text.Megaparsec

data Err
  = TypeError Type Type
  | UnificationMismatch [Type] [Type]
  | InfiniteType TVar Type
  | TypeText Text
  | NotFoundError Text
  | DuplicateError Text
  | ParseError (ParseError (Token Text) (Void))
  | RunError Text
  | InternalErr
  deriving (Show)

data Name = Name
  { nameId   :: Int
  , nameOrig :: Text
  } deriving (Show, Eq, Ord)

newtype TVar = TV Text
  deriving (Show, Eq, Ord)

data Scheme = Forall [TVar] Type deriving (Show)

instance T.Typed Scheme where
  typeOf (Forall xs t) = T.typeOf t

data Type
  = Type Text
  | TFunc [Type] Type
  | TVar TVar
  deriving (Show, Eq, Ord)

instance T.Typed Type where
  typeOf (TVar t) = T.ptr T.i8
  typeOf (TFunc args ret) = T.FunctionType (T.typeOf ret) (map T.typeOf args) False
  typeOf (Type t) = case t of
                      "Int"   -> T.ptr T.i64
                      "Float" -> T.ptr T.double
                      "Unit"  -> T.ptr T.i8

int = Type "Int"
float = Type "Float"
unit = Type "Unit"
intf1 = TFunc [int] int
intf2 = TFunc [int, int] int

primTypes :: M.Map Text Type
primTypes = M.fromList
  [ f2 "add" int
  , f2 "+" int
  , f2 "-" int
  , f2 "sub" int
  , f2 "mul" int
  , f2 "div" int
  , f2 "rem" int
  , f2 "fadd" float
  , f2 "fsub" float
  , f2 "fmul" float
  , f2 "fdiv" float
  , f2 "frem" float
  ]
    where
      f2 n t = (n,TFunc [t,t] t)

lookupPrim :: Text -> Type
lookupPrim x = M.findWithDefault (error "no prim") x primTypes
