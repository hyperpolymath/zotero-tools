||| Memory Layout Proofs — ABI Foundation.
|||
||| This module provides the formal proofs required to ensure that 
||| Idris data structures are binary-compatible with the C/Zig layer.

module ZOTERHO.ABI.Layout

import ZOTERHO.ABI.Types
import Data.Vect
import Data.So

%default total

--------------------------------------------------------------------------------
-- Utilities
--------------------------------------------------------------------------------

||| CALCULATOR: Determines the padding required to reach the next alignment boundary.
public export
paddingFor : (offset : Nat) -> (alignment : Nat) -> Nat
paddingFor offset alignment =
  if offset `mod` alignment == 0
    then 0
    else alignment - (offset `mod` alignment)

||| NORMALIZER: Rounds a size up to the nearest multiple of `alignment`.
public export
alignUp : (size : Nat) -> (alignment : Nat) -> Nat
alignUp size alignment =
  size + paddingFor size alignment

--------------------------------------------------------------------------------
-- Struct Layout Logic
--------------------------------------------------------------------------------

||| FIELD METADATA: Tracks the physical footprint of a single record field.
public export
record Field where
  constructor MkField
  name : String
  offset : Nat
  size : Nat
  alignment : Nat

||| LAYOUT SPECIFICATION: A collection of fields with formal safety proofs.
public export
record StructLayout where
  constructor MkStructLayout
  fields : Vect n Field
  totalSize : Nat
  alignment : Nat
  -- INVARIANT: The total size must be at least the sum of all field sizes.
  {auto 0 sizeCorrect : So (totalSize >= sum (map (\f => f.size) fields))}
  -- INVARIANT: The total size must be a multiple of the alignment.
  {auto 0 aligned : Divides alignment totalSize}
