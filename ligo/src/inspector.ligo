(** Helper contract to query FA2 `Balance_of` entry point *)
#include "fa2_interface.ligo"

type storage is
  | State of list(balance_of_response)
  | Empty

type query_param is record [
  fa2 : address;
  requests : list(balance_of_request);
]

type param is
  | Query of query_param
  | Response of list(balance_of_response)
  | Default of unit

function main (const p : param; const s : storage) : (list(operation)) * storage is
  case p of
  | Query (q) -> block {
    (* preparing balance_of request and invoking FA2 *)

    const bp : balance_of_param = case (Tezos.get_entrypoint_opt("%response", Tezos.self_address) : option(contract(list(balance_of_response)))) of 
      Some (callback) -> record [
        requests = q.requests;
        callback = callback
      ]
    | None -> (failwith ("TODO: write proper error message here") : balance_of_param)
    end;
    const fa2 : contract(balance_of_param) = case (Tezos.get_entrypoint_opt("%balance_of", q.fa2): option(contract(balance_of_param))) of 
      Some (t) -> t
    | None -> (failwith ("TODO: write proper error message here") : contract(balance_of_param))
    end;
    const q_op = Tezos.transaction(bp, 0mutez, fa2);
  } with (list [q_op], s)
  | Response (responses) ->
    (* 
    getting FA2 balance_of_response and putting it into storage
    for off-chain inspection
    *)
    ((list [] : list(operation)), State(responses))

  | Default (u) -> ((list [] : list(operation)), s)
  end