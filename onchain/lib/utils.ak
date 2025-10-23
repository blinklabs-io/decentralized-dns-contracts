use aiken/builtin.{
  blake2b_256, head_list, unconstr_fields, verify_ecdsa_secp256k1_signature,
}
use aiken/collection/dict.{empty, insert, size, to_pairs}
use aiken/collection/list.{all, any, filter}
use aiken/option.{is_none}
use aiken/primitive/bytearray.{concat}
use cardano/address.{Address, Script}
use cardano/assets.{
  AssetName, PolicyId, Value, policies, quantity_of, to_dict, tokens,
  without_lovelace,
}
use cardano/transaction.{Datum, Input, Output}

pub fn create_reference_token_tn(tld: ByteArray) -> ByteArray {
  blake2b_256(concat("r", tld))
}

pub fn create_user_token_tn(tld: ByteArray) -> ByteArray {
  blake2b_256(concat("u", tld))
}

pub fn verify_tld_signature(
  verification_key: ByteArray,
  tld: ByteArray,
  signature: ByteArray,
) -> Bool {
  verify_ecdsa_secp256k1_signature(
    verification_key,
    blake2b_256(tld),
    signature,
  )
}

pub fn check_output_exist(
  outputs: List<Output>,
  policy_id: PolicyId,
  tn: AssetName,
  address: Address,
  datum: Datum,
) -> Bool {
  any(
    outputs,
    fn(output) {
      quantity_is_one(output.value, policy_id, tn)? && output.address == address && (output.datum == datum)? && is_none(
        output.reference_script,
      )? && two_token_value(output.value)?
    },
  )
}

/// Check if only one token name with a specific policy id is an value with given amount.
/// Useful to check minting values.
pub fn single_name_of_policy_id(
  value: Value,
  cs: PolicyId,
  tn: AssetName,
  am: Int,
) -> Bool {
  insert(empty, tn, am) == tokens(value, cs)
}

pub fn all_burned(mint: Value, policy_id: PolicyId) -> Bool {
  all(to_pairs(tokens(mint, policy_id)), fn(Pair(_, am)) { am < 0 })
}

/// Check there are exactly 2 tokens in a value.
/// Useful to check there is only ada and one native token in a value.
pub fn two_token_value(value: Value) -> Bool {
  when
    value
      |> without_lovelace
      |> to_dict
      |> to_pairs
  is {
    [Pair(_cs, tn_ams)] -> size(tn_ams) == 1
    _ -> False
  }
}

/// Check there exists a policy id and token name with amount 1 in a value.
pub fn quantity_is_one(value: Value, cs: PolicyId, tn: AssetName) -> Bool {
  quantity_of(value, cs, tn) == 1
}

/// Get the script hash of an address. Address must have a script payment part. 
/// Useful if a script is for spending and minting.
/// ```aiken
/// let address = Address(Script("7c9f5b4a2d3e89f04c7a12d3be68a1e7f9bde64321a7fcd8e5a9031b"), None)
/// get_script_hash_from_address(addres) == "7c9f5b4a2d3e89f04c7a12d3be68a1e7f9bde64321a7fcd8e5a9031b"
///```
pub fn get_script_hash_from_address(address: Address) -> ByteArray {
  expect Script(script_hash) = address.payment_credential
  script_hash
}

/// Check if a policy id is present in an output
pub fn policy_id_present_in_output(output: Output, policy_id: PolicyId) -> Bool {
  output.value
    |> policies
    |> any(fn(n) { n == policy_id })
}

/// Check if a policy id is present in a list of outputs
pub fn policy_id_present_in_outputs(
  outputs: List<Output>,
  policy_id: PolicyId,
) -> Bool {
  any(outputs, fn(output) { policy_id_present_in_output(output, policy_id) })
}

/// Check if a policy id is present in a list of outputs
pub fn filter_single_token_in_outputs(
  outputs: List<Output>,
  policy_id: PolicyId,
  tn: AssetName,
) -> List<Output> {
  filter(outputs, fn(output) { quantity_is_one(output.value, policy_id, tn) })
}

pub fn filter_input_with_single_token(
  inputs: List<Input>,
  policy_id: PolicyId,
  tn: AssetName,
) -> List<Input> {
  filter(
    inputs,
    fn(input) { quantity_is_one(input.output.value, policy_id, tn) },
  )
}

pub fn single_token_in_inputs(
  inputs: List<Input>,
  policy_id: PolicyId,
  tn: AssetName,
) -> Bool {
  any(inputs, fn(input) { quantity_is_one(input.output.value, policy_id, tn) })
}

pub fn get_inline_datum_output(output: Output) -> Data {
  head_list(unconstr_fields(output.datum))
}
