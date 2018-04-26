{-# LANGUAGE DuplicateRecordFields, OverloadedStrings  #-}
module Codegen.Decl where
import GHC.Generics hiding (Constructor)
import Codegen.Expr
import Codegen.Fix
import Data.Aeson
import Data.HashMap.Strict

-- Declarations
data Declaration =
    IndDecl { name :: Maybe String, argnames :: Maybe [String], constructors :: [Constructor] }
  | TypeDecl { name :: Maybe String, argnames :: Maybe [String], value :: Maybe Expr }
  | FixDecl { fixlist :: Maybe [Fix] }
  | TermDecl { name :: Maybe String, typ :: Maybe Typ, value :: Maybe Expr }
    deriving (Show, Eq)

instance FromJSON Declaration where
  parseJSON (Object v) =
      case (v ! "what") of
        "decl:ind"      -> IndDecl <$> v .:? "name"
                                   <*> v .:? "argnames"
                                   <*> v .:  "constructors"
        "decl:type"     -> TypeDecl <$> v .:? "name"
                                    <*> v .:?  "argnames"
                                    <*> v .:?  "value"
        "decl:fixgroup" -> FixDecl <$> v .:? "fixlist"
        "decl:term"     -> TermDecl <$> v .:? "name"
                                    <*> v .:?  "type"
                                    <*> v .:?  "value"
        _               -> fail ("Unknown declaration type: " ++ (show v))

