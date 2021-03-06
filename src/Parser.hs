{-# LANGUAGE OverloadedStrings #-}
module Parser where

import           Data.Bifunctor
import           Data.Text                  (Text)
import qualified Data.Text                  as T
import           Data.Void
import           Text.Megaparsec            hiding (count, match)
import           Text.Megaparsec.Char
import qualified Text.Megaparsec.Char.Lexer as L

import           Core
import           Type                       (Err (..))

type Parser = Parsec Void Text

sc :: Parser ()
sc = L.space space1 lineCmnt blockCmnt
  where
    lineCmnt  = L.skipLineComment "//"
    blockCmnt = L.skipBlockComment "/*" "*/"

lexeme :: Parser a -> Parser a
lexeme = L.lexeme sc

symbol :: Text -> Parser Text
symbol = L.symbol sc

parens :: Parser a -> Parser a
parens = between (symbol "(") (symbol ")")

braces :: Parser a -> Parser a
braces = between (symbol "{") (symbol "}")

integer :: Parser Int
integer = lexeme L.decimal

hexInteger :: Parser Int
hexInteger = lexeme L.hexadecimal

parseFloat :: Parser Float
parseFloat = lexeme L.float

charLit :: Parser Char
charLit = lexeme L.charLiteral

symbolIdentifier, identifier, capIdentifier, lowIdentifier :: Parser Text
(symbolIdentifier, identifier, capIdentifier, lowIdentifier) =
  (ident symP, ident p, ident upP, ident lowP)
  where
    ident f = T.pack <$> (lexeme . try) f
    sym     = oneOf ("!@#$%^&*<>+-=./~;" :: String)
    symP    = (:) <$> sym <*> many sym
    p       = (:) <$> letterChar <*> many alphaNumChar
    lowP    = (:) <$> lowerChar <*> many alphaNumChar
    upP     = (:) <$> upperChar <*> many alphaNumChar

commaSep :: Parser a -> Parser [a]
commaSep = flip sepBy (symbol ",")

-- parser

parseLit :: Parser Lit
parseLit =
  try (Float <$> parseFloat)
  <|> Int <$> integer
  -- <|> Char <$> charLit

parseLam :: Parser Expr
parseLam = do
  args <- parseArgs lowIdentifier
  symbol "->"
  e <- parseExpr
  return $ lam () args args e

parseCase :: Parser Expr
parseCase = do
  symbol "case"
  e <- parseExpr
  braces $ do
    alts <- many $ do
      p <- parsePat
      symbol "->"
      body <- parseExpr
      return $ alt p body
    return $ Case () e () alts
  where
    parsePat =
      (Right <$> parseLit)
      <|> (Left <$> lowIdentifier)

parseArgs :: Parser a -> Parser [a]
parseArgs = parens . commaSep

parseLet :: Parser Expr
parseLet = do
  symbol "let"
  xs <- many $ try $ do
    n <- lowIdentifier
    symbol "="
    val <- parseExpr
    return (n, val)
  symbol "in"
  next <- parseExpr
  return $ let_ () [] (map fst xs) xs next

parseCall :: Parser Expr
parseCall = try $ do
  n <- lowIdentifier
  args <- parseArgs parseExpr
  return $ Call () (V n) args

parseExpr :: Parser Expr
parseExpr = do
  e1 <- f
  inf <- optional symbolIdentifier
  case inf of
    Nothing -> return e1
    Just bi -> do
      e2 <- parseExpr
      return $ Call () (V bi) [e1,e2]
  where
    f =   parseLet
      <|> parseCase
      <|> parseCall
      <|> parseLam
      <|> V <$> lowIdentifier
      <|> Lit <$> parseLit

mainParse :: Parser Expr
mainParse = between sc eof parseExpr

parseText :: String -> Text -> Either Err (Core () Text)
parseText fileName t = first ParseError $ parse mainParse fileName t
