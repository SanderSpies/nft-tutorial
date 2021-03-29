(** 
Reference implementation of the FA2 operator storage, config API and 
helper functions 
*)

#if !FA2_OPERATOR_LIB
#define FA2_OPERATOR_LIB

#include "fa2_errors.ligo"

(** 
(owner, operator, token_id) -> unit
To be part of FA2 storage to manage permitted operators
*)
type operator_storage is big_map ((address * (address * token_id)), unit)

(** 
  Updates operator storage using an `update_operator` command.
  Helper function to implement `Update_operators` FA2 entrypoint
*)
function update_operators (const update : update_operator; const storage : operator_storage)
    : operator_storage is
  case update of
  | Add_operator (op) -> 
    Big_map.update ((op.owner, (op.operator, op.token_id)), (Some (unit)), storage)
  | Remove_operator (op) -> 
    Big_map.remove ((op.owner, (op.operator, op.token_id)), storage)
  end

(**
Validate if operator update is performed by the token owner.
@param updater an address that initiated the operation; usually `Tezos.sender`.
*)
function validate_update_operators_by_owner (const update : update_operator; const updater : address)
    : unit is block {
      const op = case update of 
        | Add_operator (op) -> op
        | Remove_operator (op) -> op
      end;
      if (op.owner = updater) then skip else failwith (fa2_not_owner)
    } with unit

(**
  Generic implementation of the FA2 `%update_operators` entrypoint.
  Assumes that only the token owner can change its operators.
 *)
function fa2_update_operators (const updates : list(operator); const storage : operator_storage) : operator_storage is block {
  const updater = Tezos.sender;
  function process_update (const ops : operator_storage; const update : update_operator) is block {
    const u = validate_update_operators_by_owner (update, updater); 
  } with update_operators(update, ops)
} with List.fold(process_update, updates, storage)

(** 
  owner * operator * token_id * ops_storage -> unit
*)
type operator_validator is (address * address * token_id * operator_storage) -> unit

(**
Create an operator validator function based on provided operator policy.
@param tx_policy operator_transfer_policy defining the constrains on who can transfer.
@return (owner, operator, token_id, ops_storage) -> unit
 *)
function make_operator_validator (const tx_policy : operator_transfer_policy) : operator_validator is block {
  const x = case tx_policy of 
  | No_transfer -> (failwith (fa2_tx_denied) : bool * bool)
  | Owner_transfer -> (true, false)
  | Owner_or_operator_transfer -> (true, true)
  end;
  const can_owner_ts = x.0; 
  const can_operator_tx = x.1;
} with
  function (const owner : address; const operator : address; const token_id : token_id; const ops_storage : operator_storage): is block {
    failwith (9fa2_not_owner)

  }

(**
Default implementation of the operator validation function.
The default implicit `operator_transfer_policy` value is `Owner_or_operator_transfer`
 *)
function default_operator_validator (const owner : address; const operator : address; const token_id : token_id; const ops_storage : operator_storage) : operator_validator is block {
  if owner = operator
  then unit (* transfer by the owner *)
  else if Big_map.mem ((owner, (operator, token_id)), ops_storage)
  then unit (* the operator is permitted for the token_id *)
  else failwith (fa2_not_operator) (* the operator is not permitted for the token_id *)
}

(** 
Validate operators for all transfers in the batch at once
@param tx_policy operator_transfer_policy defining the constrains on who can transfer.
*)
function validate_operator (const tx_policy : operator_transfer_policy; const txs : list(transfer); const ops_storage : operator_storage) : unit is block {
  const validator = make_operator_validator (tx_policy);
  List.iter (function (const tx : transfer) is 
    List.iter (function (const dst : transfer_destination) is 
      validator (tx.from_, Tezos.sender, dst.token_id ,ops_storage),
      tx.txs),
    txs)
}

#endif
