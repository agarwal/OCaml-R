(*********************************************************************************)
(*                OCaml-R                                                        *)
(*                                                                               *)
(*    Copyright (C) 2008-2009 Institut National de Recherche en                  *)
(*    Informatique et en Automatique. All rights reserved.                       *)
(*                                                                               *)
(*    This program is free software; you can redistribute it and/or modify       *)
(*    it under the terms of the GNU General Public License as                    *)
(*    published by the Free Software Foundation; either version 3 of the         *)
(*    License, or  any later version.                                            *)
(*                                                                               *)
(*    This program is distributed in the hope that it will be useful,            *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of             *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the              *)
(*    GNU Library General Public License for more details.                       *)
(*                                                                               *)
(*    You should have received a copy of the GNU General Public                  *)
(*    License along with this program; if not, write to the Free Software        *)
(*    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA                   *)
(*    02111-1307  USA                                                            *)
(*                                                                               *)
(*    Contact: Maxence.Guesdon@inria.fr                                          *)
(*                                                                               *)
(*********************************************************************************)

external init_r : string array -> int = "init_r";;
let init ?(argv=Sys.argv) () = init_r argv;;
external terminate : unit -> unit = "end_r";;


module type Rinterface = sig
    type sexp
    type symbol = string
    type arg = [ `Anon of sexp | `Named of symbol * sexp ]
    val sexp : string -> sexp
    val sexp_of_symbol : symbol -> sexp
    val set_var : symbol -> sexp -> unit
    val r_print_value : sexp -> unit
    val exec : string -> arg array -> unit
    val to_bool : sexp -> bool
    val to_int : sexp -> int
    val to_float : sexp -> float
    val to_string : sexp -> string
    val of_bool : bool -> sexp
    val of_int : int -> sexp
    val of_float : float -> sexp
    val of_string : string -> sexp
    val to_bool_array : sexp -> bool array
    val to_int_array : sexp -> int array
    val to_float_array : sexp -> float array
    val to_string_array : sexp -> string array
    val of_bool_array : bool array -> sexp
    val of_int_array : int array -> sexp
    val of_float_array : float array -> sexp
    val of_string_array : string array -> sexp
    val get_attrib : sexp -> string -> sexp
    val dim : sexp -> int array
    val dimnames : sexp -> string array
end;;

module Rinterface_impl : Rinterface =
  struct
    type sexp
    type symbol = string
    type arg = [
        `Named of symbol * sexp
      | `Anon of sexp
      ]

    external sexp : string -> sexp = "r_sexp_of_string"
    external sexp_of_symbol : symbol -> sexp = "r_sexp_of_symbol"
    external set_var : symbol -> sexp -> unit = "r_set_var"
    external r_print_value : sexp -> unit = "r_print_value"
    external exec : string -> arg array -> unit = "r_exec"

    external to_bool : sexp -> bool = "bool_of_sexp"
    external to_int : sexp -> int = "int_of_sexp"
    external to_float : sexp -> float = "float_of_sexp"
    external to_string : sexp -> string = "string_of_sexp"

    external of_bool : bool -> sexp = "sexp_of_bool"
    external of_int : int -> sexp = "sexp_of_int"
    external of_float : float -> sexp = "sexp_of_float"
    external of_string : string -> sexp = "sexp_of_string"

    external to_bool_array : sexp -> bool array = "bool_array_of_sexp"
    external to_int_array : sexp -> int array = "int_array_of_sexp"
    external to_float_array : sexp -> float array = "float_array_of_sexp"
    external to_string_array : sexp -> string array = "string_array_of_sexp"

    external of_bool_array : bool array -> sexp = "sexp_of_bool_array"
    external of_int_array : int array -> sexp = "sexp_of_int_array"
    external of_float_array : float array -> sexp = "sexp_of_float_array"
    external of_string_array : string array -> sexp = "sexp_of_string_array"

    external get_attrib : sexp -> string -> sexp = "r_get_attrib"

    let dim sexp = to_int_array (get_attrib sexp "dim");;
    let dimnames sexp = to_string_array (get_attrib sexp "dimnames");;

(*
external to_matrix : (sexp -> 'a) -> sexp -> 'a array array = "to_matrix"
external of_matrix : ('a -> sexp) -> 'a array array -> sexp = "of_matrix"


let to_bool_matrix = to_matrix to_bool;;
let to_int_matrix = to_matrix to_int;;
let to_float_matrix = to_matrix to_float;;
let to_string_matrix = to_matrix to_string;;

let of_bool_matrix = of_matrix of_bool;;
let of_int_matrix = of_matrix of_int;;
let of_float_matrix = of_matrix of_float;;
let of_string_matrix = of_matrix of_string;;
*)
end

include Rinterface_impl;;

(** Functor to properly set up R environment variables. *)

module type R_Environment =
sig
  val variables : (string * string) list
end

module Interpreter (Env : R_Environment) : sig
    include Rinterface
  end =
struct
  include Rinterface_impl
  exception Initialisation_failed
  let () = List.iter (function name, value -> Unix.putenv name value)
    Env.variables

  let () = match init_r [|"R"|] with
    | 1 -> () | _ -> raise Initialisation_failed
end