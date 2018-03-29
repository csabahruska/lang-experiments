{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE FlexibleContexts #-}
{-# LANGUAGE RecursiveDo #-}
module Emit where

import           Data.Text                  (Text)
import qualified Data.Text                  as T
import           LLVM.AST                   hiding (function)
import Bound (instantiate, instantiate1, Scope)
import qualified LLVM.AST                   as AST
import LLVM.AST.Float
import qualified LLVM.AST.CallingConvention as CC
import           LLVM.AST.Constant as C
import           LLVM.AST.Global as G
import           LLVM.AST.Type
import qualified LLVM.AST.IntegerPredicate as I
import qualified LLVM.AST.FloatingPointPredicate as F
import           LLVM.AST.Typed
import           LLVM.IRBuilder
import qualified LLVM.AST.Attribute as A
import LLVM.IRBuilder.Internal.SnocList
import Control.Monad.State hiding (void)

-- import           Codegen
import qualified Core                       as Core
import qualified Type as T

-- | Define and emit a (non-variadic) function definition
functionWithAttr
  :: MonadModuleBuilder m
  => Name  -- ^ Function name
  -> [Either A.GroupID A.FunctionAttribute]
  -> [(Type, ParameterName)]  -- ^ Parameter types and name suggestions
  -> Type  -- ^ Return type
  -> ([Operand] -> IRBuilderT m a)  -- ^ Function body builder
  -> m Operand
functionWithAttr label attr argtys retty body = do
  let tys = fst <$> argtys
  (paramNames, blocks) <- runIRBuilderT emptyIRBuilder $ do
    paramNames <- forM argtys $ \(_, paramName) -> case paramName of
      NoParameterName -> fresh
      ParameterName p -> fresh `named` p
    body $ zipWith LocalReference tys paramNames
    return paramNames
  let
    def = GlobalDefinition functionDefaults
      { name        = label
      , parameters  = (zipWith (\ty nm -> Parameter ty nm []) tys paramNames, False)
      , returnType  = retty
      , basicBlocks = blocks
      , G.functionAttributes = attr
      }
    funty = ptr $ FunctionType retty (fst <$> argtys) False
  emitDefn def
  pure $ ConstantOperand $ C.GlobalReference funty label

instance MonadIRBuilder m => MonadIRBuilder (ModuleBuilderT m) where
  liftIRState = lift . liftIRState

instance MonadModuleBuilder m => MonadModuleBuilder (IRBuilderT m) where
  liftModuleState = lift . liftModuleState

newtype Supply = Supply Word

runEmit :: Core.Core T.Scheme (T.Name, T.Scheme) -> Int -> AST.Module
runEmit core count = flip evalState (Supply 0) $ buildModuleT "main" $ do
    setup
    let newCore = (\(n, s) -> (pure . ConstantOperand . GlobalReference (ptr $ typeOf s) . mkName . T.unpack . T.nameOrig $ n)) <$> core

    function "userMain" [] (ptr i64) $ \_ -> convert newCore >>= ret

convertLit :: (MonadState Supply m, MonadModuleBuilder m, MonadIRBuilder m) 
           => Core.Lit -> m Operand
convertLit = \case
  Core.Int i -> do
    space <- malloc -- alloca i64 Nothing 0
    store space 0 (ConstantOperand $ Int 64 $ toInteger i)
    return space
  -- Core.Float f -> return $ Float $ Double f
  -- Core.Char c -> $ Int 8 $ toInteger $ fromEnum c
  _ -> error "not done yet"

cmpLit :: (MonadIRBuilder m) => Operand -> Operand -> m Operand
cmpLit a b = do
  x <- getLit a
  y <- getLit b
  -- assume the same type (typechecker)
  case typeOf x of
    IntegerType _ -> do
      icmp I.EQ x y
    FloatingPointType _ -> do
      fcmp F.OEQ x y
  where
    getLit opr =
      case typeOf opr of
        PointerType t _ -> do
          load opr 0 >>= getLit
        IntegerType _ -> pure opr
        FloatingPointType _ -> pure opr

convert :: ( MonadFix m, MonadState Supply m, MonadModuleBuilder m)
           -- , MonadIRBuilder f)
        => Core.Core T.Scheme (IRBuilderT m Operand) -> IRBuilderT m Operand
convert = \case 
  Core.Call t n args -> do
    irn <- convert n
    irs <- mapM convert args
    call irn [(a,[]) | a <- irs]
  Core.Lit l -> convertLit l
  Core.V n -> n
  Core.Let t i ts sc se -> do
    -- todo mutual dependence in fns
    let f (n,t) = Core.V $ undefined
        argsE = map 
          (instantiate (map f (undefined) !!))
          sc
        init :: Monad m 
             => [Scope Int (Core.Core T.Scheme) (IRBuilderT m Operand)]
             -> [Operand] -> [Core.Core T.Scheme (IRBuilderT m Operand)]
        init scope elem = 
          map (instantiate (\i -> Core.V $ pure (elem !! i))) scope

    rec res <- forM (init sc res) $ \(core) -> convert core
      
    convert $ instantiate (pure . pure . (res !!)) se
  Core.Case t predCore armT arms -> do
    pred <- convert predCore
    finalizer <- fresh
    ends <- (convertAlt finalizer pred) arms
    emitBlockStart finalizer
    phi ends

  Core.Lam (T.Forall _ (T.TFunc argT retT)) i sc -> do
    n <- freshGlobal
    lift $ functionWithAttr
      n
      []
      [(typeOf x, NoParameterName) | x <- argT]
      (typeOf retT)
      (\args -> convert (instantiate (\x -> Core.V . pure $ args !! x) sc) >>= ret)

  _ -> pure $ ConstantOperand $ Int 64 2

-- | create a test and br
--   make a new block
convertAlt :: (MonadFix m, MonadState Supply m, MonadModuleBuilder m)
           => Name
           -> Operand 
           -> [Core.Alt (Core.Core T.Scheme) (IRBuilderT m Operand)]
           -> IRBuilderT m [(Operand, Name)]
convertAlt final _ [] = do
  str <- mkString "case not complete"
  puts str
  exit
  pure []
convertAlt final pred (a:as) = do
  let (Core.Alt p sc) = a

  case p of
    Core.PLit l -> do
      lOpr <- convertLit l
      b <- cmpLit pred lOpr
      trueName <- fresh
      falseName <- fresh
      condBr b trueName falseName
      emitBlockStart trueName
      val <- convert $ instantiate1 undefined sc
      br final
      emitBlockStart falseName
      ((val,trueName) :) <$> convertAlt final pred as
      
    Core.PVar -> do
      let c = instantiate1 (pure . pure $ pred) sc

      name <- fresh
      br name
      emitBlockStart name
      oper <- convert c
      br final
      pure [(oper, name)]

freshGlobal :: MonadState Supply m => m Name
freshGlobal = do
  Supply n <- get
  return $ UnName n

mkString :: (MonadState Supply m, MonadModuleBuilder m) => String -> m (Operand)
mkString str = do
  name <- freshGlobal
  let arrT = ArrayType (fromInteger $ toInteger $ length str) i8
  emitDefn $ GlobalDefinition globalVariableDefaults
    { name = name
    , G.type' = arrT
    , isConstant = True
    , initializer = Just $ Array i8 $ map (Int 8 . toInteger . fromEnum) str
    }
  return $ ConstantOperand $ GlobalReference (ptr arrT) $ name

puts :: MonadIRBuilder m => Operand -> m Operand
puts str = do
  call (ConstantOperand $ GlobalReference (FunctionType VoidType [ptr i8] False) "puts")
    [(str, [])]

exit :: MonadIRBuilder m => m Operand
exit = call (ConstantOperand $ GlobalReference (FunctionType VoidType [] False) "exit") []

malloc :: MonadIRBuilder m => m Operand
malloc = do
  let ft = ptr $ FunctionType (ptr i8) [i64] False
      size = ConstantOperand $ Int 64 4
      
  space <- call (ConstantOperand $ GlobalReference ft "malloc") [(size,[])]
  bitcast space (ptr i64)

mkPrelude :: (MonadState Supply m, MonadModuleBuilder m) => m ()
mkPrelude = do
  extern "puts" [ptr i8] void
  extern "malloc" [i64] (ptr i8)
  extern "exit" [] void
  extern "fflush" [ptr i8] void
  functionWithAttr
    "add" 
    [Right A.AlwaysInline]
    [(ptr i64, NoParameterName), (ptr i64, NoParameterName)] 
    (ptr i64) 
    $ \[a,b] -> do
      x <- load a 0
      y <- load b 0
      sum <- add x y
      space <- malloc
      store space 0 sum
      ret space
  functionWithAttr
    "sub" 
    [Right A.AlwaysInline]
    [(ptr i64, NoParameterName), (ptr i64, NoParameterName)] 
    (ptr i64) 
    $ \[a,b] -> do
      x <- load a 0
      y <- load b 0
      sum <- sub x y
      space <- malloc
      store space 0 sum
      ret space
  return ()

setup :: (MonadState Supply m, MonadModuleBuilder m) => m ()
setup = do
  mkPrelude
  function "main" [] (i64) buildMain
  return ()

buildMain :: Monad m => [AST.Operand] -> IRBuilderT m ()
buildMain _ = do
  let toT t a = ptr $ FunctionType t a False
      toF n t ta = Right $ ConstantOperand $ GlobalReference (toT t ta) $ mkName n
      fnT = ptr $ FunctionType void [ptr i8] False
      exitT = ptr $ FunctionType void [] False
      puts = toF "puts" void [ptr i8]
      fflush = toF "fflush" void [ptr i8]
      null = (ConstantOperand $ C.IntToPtr (Int 8 0) (ptr i8), [])

  -- emitInstrVoid $ Call Nothing CC.C [] puts [(str, [])] [] []
  r <- call (ConstantOperand $ GlobalReference (toT (ptr i64) []) "userMain") []
  emitInstrVoid $ Call Nothing CC.C [] fflush [null] [] []
  ret =<< load r 0
