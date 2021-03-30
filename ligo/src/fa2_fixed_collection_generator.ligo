#include "fa2_fixed_collection_token.ligo"

(* helper storage generator *)

type token_descriptor is record [
  id : token_id;
  symbol : string;
  name : string;
  token_uri : option(string);
  owner : address;
]

function generate_asset_storage (const tokens : list(token_descriptor); const owner: address) : collection_storage is
  block {
    const ledger = List.fold (
      function (const ledger : ledger; const td : token_descriptor) is 
        Big_map.add(td.id, td.owner, ledger),
      tokens,
      (Big_map.empty : ledger)
    );
    const metadata = List.fold (
      function (const meta : token_metadata_storage; const td : token_descriptor) is 
        block {
          const m0 : token_metadata = record [
            token_id  = td.id;
            symbol    = td.symbol;
            name      = td.name;
            decimals  = 0n;
            extras    = (Map.empty : map(string, string))
          ];
          const m1 = case td.token_uri of 
            None -> m0
          | Some (uri) -> m0 with record [extras = Map.add("token_uri", uri, m0.extras)]
          end
        } with Big_map.add(td.id, m1, meta),
      tokens,
      (Big_map.empty : token_metadata_storage)
    );
    const cs = record [
      ledger = ledger;
      operators = (Big_map.empty : operator_storage);
      token_metadata = metadata;
    ];
  } 
  with cs

function generate_rainbow_collection_storage (const owner : address) is 
  block {
    const uri : option(string) = None;
    const tokens : list(token_descriptor) = list [
      record [ id = 0n; symbol = "RED"; name = "RAINBOW_TOKEN"; owner = owner; token_uri = uri];
      record [ id = 1n; symbol = "ORANGE"; name = "RAINBOW_TOKEN"; owner = owner; token_uri = uri];
      record [ id = 2n; symbol = "YELLOW"; name = "RAINBOW_TOKEN"; owner = owner; token_uri = uri];
      record [ id = 3n; symbol = "GREEN"; name = "RAINBOW_TOKEN"; owner = owner; token_uri = uri];
      record [ id = 4n; symbol = "BLUE"; name = "RAINBOW_TOKEN"; owner = owner; token_uri = uri];
      record [ id = 5n; symbol = "INDIGO"; name = "RAINBOW_TOKEN"; owner = owner; token_uri = uri];
      record [ id = 6n; symbol = "VIOLET"; name = "RAINBOW_TOKEN"; owner = owner; token_uri = uri];
    ]
  } 
  with generate_asset_storage (tokens, owner)


(*
CLI:
ligo compile-storage ligo/src/fa2_fixed_collection_generator.mligo fa2_collection_main '
generate_rainbow_collection_storage ("tz1YPSCGWXwBdTncK2aCctSZAXWvGsGwVJqU" : address)'
*)