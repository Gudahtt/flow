(**
 * Copyright (c) 2013-present, Facebook, Inc.
 *
 * This source code is licensed under the MIT license found in the
 * LICENSE file in the root directory of this source tree.
 *)

module Ast = Flow_ast

module Annot_path = struct
  type t =
    | Annot of (Loc.t, Loc.t) Ast.Type.annotation
    | Object of t * string
    | Array of t * int

  let mk_annot ?annot_path = function
    | None -> annot_path
    | Some annot -> Some (Annot (annot))

  let mk_object ?annot_path x =
    match annot_path with
      | None -> None
      | Some annot_path -> Some (Object (annot_path, x))

  let mk_array ?annot_path i =
    match annot_path with
      | None -> None
      | Some annot_path -> Some (Array (annot_path, i))
end

module Sort = struct
  type t = Type | Value
  let to_string = function
    | Type -> "type"
    | Value -> "value"

  let is_import_type =
    let open Ast.Statement.ImportDeclaration in
    function
    | ImportType | ImportTypeof -> true
    | ImportValue -> true (* conditional *)

  let is_import_value =
    let open Ast.Statement.ImportDeclaration in
    function
    | ImportType | ImportTypeof -> false
    | ImportValue -> true

  let of_import_kind =
    let open Ast.Statement.ImportDeclaration in
    function
    | ImportValue | ImportTypeof -> Value
    | ImportType -> Type
end

type t =
  | VariableDef of {
      annot: Annot_path.t option
    }
  | FunctionDef of {
      tparams: (Loc.t, Loc.t) Ast.Type.ParameterDeclaration.t option;
      params: (Loc.t, Loc.t) Ast.Function.Params.t;
      return: (Loc.t, Loc.t) Ast.Type.annotation option;
    }
  | DeclareFunctionDef of {
      annot: (Loc.t, Loc.t) Ast.Type.annotation;
    }
  | ClassDef of {
      tparams: (Loc.t, Loc.t) Ast.Type.ParameterDeclaration.t option;
      body: (Loc.t, Loc.t) Ast.Class.Body.t;
      super: (Loc.t, Loc.t) Ast.Expression.t option;
      super_targs: (Loc.t, Loc.t) Ast.Type.ParameterInstantiation.t option;
      implements: (Loc.t, Loc.t) Ast.Class.Implements.t list;
    }
  | DeclareClassDef of {
      tparams: (Loc.t, Loc.t) Ast.Type.ParameterDeclaration.t option;
      body: (Loc.t, Loc.t) Ast.Type.Object.t;
      extends: (Loc.t * (Loc.t, Loc.t) Ast.Type.Generic.t) option;
      mixins: (Loc.t * (Loc.t, Loc.t) Ast.Type.Generic.t) list;
      implements: (Loc.t, Loc.t) Ast.Class.Implements.t list;
    }
  | TypeDef of {
      tparams: (Loc.t, Loc.t) Ast.Type.ParameterDeclaration.t option;
      right: (Loc.t, Loc.t) Ast.Type.t;
    }
  | OpaqueTypeDef of {
      tparams: (Loc.t, Loc.t) Ast.Type.ParameterDeclaration.t option;
      impltype: (Loc.t, Loc.t) Ast.Type.t option;
      supertype: (Loc.t, Loc.t) Ast.Type.t option;
    }
  | InterfaceDef of {
      tparams: (Loc.t, Loc.t) Ast.Type.ParameterDeclaration.t option;
      body: (Loc.t, Loc.t) Ast.Type.Object.t;
      extends: (Loc.t * (Loc.t, Loc.t) Ast.Type.Generic.t) list;
    }
  | ImportNamedDef of {
      kind: Ast.Statement.ImportDeclaration.importKind;
      source: Ast_utils.source;
      name: Ast_utils.ident;
    }
  | ImportStarDef of {
      kind: Ast.Statement.ImportDeclaration.importKind;
      source: Ast_utils.source;
    }
  | RequireDef of {
      source: Ast_utils.source;
    }

let to_string = function
  | VariableDef _ -> "VariableDef"
  | FunctionDef _ -> "FunctionDef"
  | DeclareFunctionDef _  -> "DeclareFunctionDef"
  | ClassDef _  -> "ClassDef"
  | DeclareClassDef _  -> "DeclareClassDef"
  | TypeDef _ -> "TypeDef"
  | OpaqueTypeDef _ -> "OpaqueTypeDef"
  | InterfaceDef _ -> "InterfaceDef"
  | ImportNamedDef _ -> "ImportNamedDef"
  | ImportStarDef _ -> "ImportStarDef"
  | RequireDef _ -> "RequireDef"

let is_type = function
  | VariableDef _ -> true (* conditional *)
  | FunctionDef _ -> false
  | DeclareFunctionDef _  -> true
  | ClassDef _  -> true
  | DeclareClassDef _  -> true
  | TypeDef _ -> true
  | OpaqueTypeDef _ -> true
  | InterfaceDef _ -> true
  | ImportNamedDef { kind; _ } -> Sort.is_import_type kind
  | ImportStarDef { kind; _ } -> Sort.is_import_type kind
  | RequireDef _ -> true (* conditional *)

let is_value = function
  | VariableDef _ -> true
  | FunctionDef _ -> true
  | DeclareFunctionDef _ -> true
  | ClassDef _  -> true
  | DeclareClassDef _ -> true
  | TypeDef _ -> false
  | OpaqueTypeDef _ -> false
  | InterfaceDef _ -> false
  | ImportNamedDef { kind; _ } -> Sort.is_import_value kind
  | ImportStarDef { kind; _ } -> Sort.is_import_value kind
  | RequireDef _ -> true

let validator = function
  | Sort.Type -> is_type
  | Sort.Value -> is_value
