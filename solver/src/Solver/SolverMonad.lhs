Copyright (c) 2016 Rodrigo Ribeiro (rodrigo@decsi.ufop.br)
                   Leandro T. C. Melo (ltcmelo@gmail.com)
                   Marcus Rodrigues (demaroar@gmail.com)

This library is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this library; if not, write to the Free Software Foundation,
Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301 USA

> module Solver.SolverMonad where

> import Data.Type
> import Data.BuiltIn

> import Data.Map (Map)
> import qualified Data.Map as Map
> import Data.Maybe (isJust, fromJust)

> import Data.Generics
> import Data.Constraints
> import Data.Type
> import Data.BuiltIn

> import Control.Monad
> import Control.Monad.Trans
> import Control.Monad.State
> import Control.Monad.Except

> import Solver.ConversionRules
> import Utils.Pretty

Definition of solver's state
============================

> type SolverM a = ExceptT String (StateT Int IO) a

> runSolverM :: SolverM a -> Int -> IO (Either String a)
> runSolverM s v = do
>                    (e, n) <- runStateT (runExceptT s) v
>                    return e

Context definitions
-------------------

> newtype TyCtx = TyCtx { tyctx :: Map Name (Ty, Bool) }
>                 deriving Eq

> instance Pretty TyCtx where
>    pprint = printer "is" . Map.map fst . tyctx

> newtype VarCtx = VarCtx { varctx :: Map Name VarInfo }
>                  deriving Eq

> instance Pretty VarCtx where
>    pprint = printer "::" . Map.map varty . varctx


Context-related functions
-------------------------

> undefVars :: Map k VarInfo -> Map k VarInfo
> undefVars = Map.filter (not . declared)

> undefTys :: Map k (a, Bool) -> Map k (a, Bool)
> undefTys = Map.filter (not . snd)


Substitution definition
-----------------------

> newtype Subst = Subst { subs :: Map Name Ty }

> nullSubst :: Subst
> nullSubst = Subst Map.empty

> instance Pretty Subst where
>     pprint = printer "+->" . subs

> (+->) :: Name -> Ty -> Subst
> n +-> t = Subst (Map.singleton n t)

Fresh variable generation
-------------------------

> fresh :: SolverM Ty
> fresh = do
>           n <- get
>           put (n + 1)
>           return (TyVar (Name ("#alpha" ++ show n)))

Auxiliar code
-------------

> printer :: String -> Map Name Ty -> Doc
> printer sep = hcat . punctuate comma . map (uncurry step) . Map.toList
>               where
>                  step n t = pprint n <+> text sep <+> pprint t

