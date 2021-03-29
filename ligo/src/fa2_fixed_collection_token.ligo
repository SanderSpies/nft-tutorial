(**
Defines non-mutable NFT collection. Once the contract is created, no tokens can
be minted or burned.
Metadata may/should contain URLs for token images and images hashes.
 *)

#if ! FA2_FIXED_COLLECTION_TOKEN
#define FA2_FIXED_COLLECTION_TOKEN

#include "fa2_interface.ligo"
#include "fa2_errors.ligo"
#include "fa2_operator_lib.ligo"


(* token_id -> token_metadata *)
type token_metadata_storage is big_map (token_id, token_metadata)

(*  token_id -> owner_address *)
type ledger is big_map (token_id, address)

type collection_storage is record [
  ledger : ledger;
  operators : operator_storage;
  token_metadata : token_metadata_storage;
]


(**
Update leger balances according to the specified transfers. Fails if any of the
permissions or constraints are violated.
@param txs transfers to be applied to the ledger
@param validate function that validates of the tokens from the particular owner can be transferred. 
 *)
function transfer (
  const txs : list(transfer), 
  const validate : operator_validator, 
  const ops_storage : operator_storage,
  const ledger : ledger) : ledger is block {
    (* process individual transfer *)
    function make_transfer (const l : ledger, const tx : transfer) is 
      List.fold (
        function (const ll : ledger, const dst : transfer_destination) is block {
          const u = validate (tx.from_, Tezos.sender, dst.token_id, ops_storage);
          if dst.amount = 0n then 
            ll (* zero amount transfer, do nothing *)
          else if dst.amount <> 1n (* for NFTs only one token per token type is available *)
          then (failwith(fa2_insufficient_balance) : ledger)
          else block {
            const owner = Big_map.find_opt(dst.token_id, ll);
            case owner of
              None -> (failwith(fa2_token_undefined) : ledger)
            | Some (o) -> block {
              if o <> tx.from_ (* check that from_ address actually owns the token *)
              then (failwith(fa2_insufficient_balance) : ledger)
              else Big_map.update(dst.token_id, Some(dst.to_), ll)
            }
          } 
        },
        tx.txs,
        l
      )
} with List.fold(make_transfer, txs, ledger)

(** 
Retrieve the balances for the specified tokens and owners
@return callback operation
*)
function get_balance (const p : balance_of_param, const ledger : ledger) : operation is block {
  function to_balance (const r : balance_of_request) is block {
    const owner = Big_map.find_opt(r.token_id, ledger);
    case owner of 
      None -> (failwith (fa2_token_undefined) : balance_of_response)
    | Some (o) -> block {
      const bal = if o = r.owner then 1n else 0n;
    } with record [request = r; balance = bal]
  }
  const responses = List.map (to_balance, p.requests);
} with Operation.transaction(responses, 0mutez, p.callback)

function fa2_collection_main (const param : fa2_entry_points, const storage : collection_storage) : (list (operation), collection_storage) is 
  case param of 
    | Transfer (txs) -> block {
      const new_ledger = transfer (txs, default_operator_validator, storage.operators, storage.ledger);
      const new_storage = storage with record [ ledger = new_ledger ]
    } with (([] : operation list), new_storage)
    | Balance_of (p) -> block {
      const op = get_balance (p, storage.ledger);
    } with ([op], storage)
    | Update_operators (updates) -> block {
      const new_operators = fa2_update_operators(updates, storage.operators);
      const new_storage = storage with record [ operators = new_operators ];
    } with (([] : operation list), new_storage)
    | Token_metadata_registry (callback) -> block {
      const callback_op = Operation.transaction(Teos.self_address, 0mutez, callback);
    } with ([callback_op], storage)

#endif