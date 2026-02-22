||| ZOTERHO — FFI Bridge Declarations
|||
||| This module defines the formal bridge to the Zoterho bibliographic
||| engine. It ensures that metadata extraction and citation proofs 
||| are handled with strict type safety at the native boundary.

module ZOTERHO.ABI.Foreign

import ZOTERHO.ABI.Types
import ZOTERHO.ABI.Layout

%default total

--------------------------------------------------------------------------------
-- Lifecycle
--------------------------------------------------------------------------------

||| Initializes the bibliographic verification engine.
export
%foreign "C:zoterho_init, libzoterho"
prim__init : PrimIO Bits64

||| Safe initialization wrapper. Returns a managed Handle.
export
init : IO (Maybe Handle)
init = do
  ptr <- primIO prim__init
  pure (createHandle ptr)

||| Shuts down the engine and releases citation buffers.
export
%foreign "C:zoterho_free, libzoterho"
prim__free : Bits64 -> PrimIO ()

||| Safe cleanup wrapper.
export
free : Handle -> IO ()
free h = primIO (prim__free (handlePtr h))
