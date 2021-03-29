#if ! FA2_INTERFACE
#define FA2_INTERFACE

type token_id is nat

type transfer_destination is
[@layout:comb]
record [
  to_ : address;
  token_id : token_id;
  amount : nat;
]

type transfer is
[@layout:comb]
record [
  from_ : address;
  txs : list(transfer_destination);
]

type balance_of_request is
[@layout:comb]
record [
  owner : address;
  token_id : token_id;
]

type balance_of_response is
[@layout:comb]
record [
  request : balance_of_request;
  balance : nat;
]

type balance_of_param is
[@layout:comb]
record [
  requests : list(balance_of_request);
  callback : contract (list(balance_of_response));
]

type operator_param is
[@layout:comb]
record [
  owner : address;
  operator : address;
  token_id: token_id;
]

type update_operator is
[@layout:comb]
  | Add_operator of operator_param
  | Remove_operator of operator_param

type token_metadata is
[@layout:comb]
record [
  token_id : token_id;
  symbol : string;
  name : string;
  decimals : nat;
  extras : map (string, string);
]

type token_metadata_param is 
[@layout:comb]
record [
  token_ids : list(token_id);
  handler : (list(token_metadata)) -> unit;
]

type fa2_entry_points is
  | Transfer of list(transfer)
  | Balance_of of balance_of_param
  | Update_operators of list(update_operator)
  | Token_metadata_registry of contract(address)

type fa2_token_metadata is
  | Token_metadata of token_metadata_param

(* permission policy definition *)

type operator_transfer_policy is
  [@layout:comb]
  | No_transfer
  | Owner_transfer
  | Owner_or_operator_transfer

type owner_hook_policy is
  [@layout:comb]
  | Owner_no_hook
  | Optional_owner_hook
  | Required_owner_hook

type custom_permission_policy is
[@layout:comb]
record [
  tag : string;
  config_api: option(address);
]

type permissions_descriptor is
[@layout:comb]
record [
  operator : operator_transfer_policy;
  receiver : owner_hook_policy;
  sender : owner_hook_policy;
  custom : option(custom_permission_policy);
]

(* permissions descriptor entrypoint
type fa2_entry_points_custom =
  ...
  | Permissions_descriptor of permissions_descriptor contract

*)


type transfer_destination_descriptor is
[@layout:comb]
record [
  to_ : option(address);
  token_id : token_id;
  amount : nat;
]

type transfer_descriptor is
[@layout:comb]
record [
  from_ : option(address);
  txs : list(transfer_destination_descriptor)
]

type transfer_descriptor_param is
[@layout:comb]
record [
  batch : list(transfer_descriptor);
  operator : address;
]

(*
Entrypoints for sender/receiver hooks

type fa2_token_receiver =
  ...
  | Tokens_received of transfer_descriptor_param

type fa2_token_sender =
  ...
  | Tokens_sent of transfer_descriptor_param
*)

#endif
