{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE OverloadedStrings #-}
module Sema.Proc where
import qualified Data.Text as T
import Common.Utils
import CIR.Expr
import Data.MonoTraversable

-- Proc semantics (monadic)
bindSemantics :: CExpr -> CExpr
-- bindSemantics s | trace ("DBG Sema/Proc.hs/bindSemantics " ++ (show s)) False = undefined
bindSemantics CExprCall { _cd = CDef { _nm = "coq_ret"  }, _cparams = [a] } = a
bindSemantics CExprCall { _cd = CDef { _nm = "coq_bind" }, _cparams = [call, CExprLambda { _lds = [CDef { .. }], .. }] } =
    CExprSeq statement $ bindSemantics _lbody
    where statement = CExprStmt (mkauto _nm) $ bindSemantics call
bindSemantics other = omap bindSemantics other

-- Remove native type instances (since Coq extracts them as arguments)
removeInstances :: CExpr -> CExpr
removeInstances CExprCall { _cparams = (v@CExprVar { .. }:ts), .. }
    | T.isPrefixOf "native" lastthing = CExprCall _cd $ map removeInstances ts
    | T.isPrefixOf "Native" lastthing = CExprCall _cd $ map removeInstances ts
    | T.isPrefixOf "show" lastthing   = CExprCall _cd $ map removeInstances ts
    | otherwise = CExprCall _cd $ map removeInstances (v:ts)
    where lastthing = last $ T.splitOn "." _var
removeInstances other = omap removeInstances other

-- Compile a Coq expression to a C Expression
retSemantics :: CExpr -> CExpr
retSemantics s@CExprSeq { .. } = listToSeq $ otherexpr s ++ [lastexpr s]
    where lastexpr  = mkreturn . last . seqToList
          otherexpr = map retSemantics . init . seqToList
          mkreturn e@CExprCall { _cd = CDef { _nm = "return" } } = e
          mkreturn e = CExprCall (mkauto "return") [e]
retSemantics e = omap retSemantics e

lambdaSemantics :: CExpr -> CExpr
lambdaSemantics s@CExprSeq { .. } = s
lambdaSemantics e@CExprCall { _cd = CDef { _nm = "return" } } = e
lambdaSemantics e = CExprCall (CDef "return" . gettype $ e) [e]

procSemantics :: CExpr -> CExpr
procSemantics = lambdaSemantics . retSemantics . removeInstances . bindSemantics
