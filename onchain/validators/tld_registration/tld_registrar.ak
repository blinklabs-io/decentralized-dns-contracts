use cardano/address.{Address, Script, StakeCredential}
use cardano/assets.{PolicyId, quantity_of}
use cardano/transaction.{
  InlineDatum, Output, OutputReference, Transaction, find_input,
}
use types.{
  OwnerAction, RegisterTLD, RegistrarAction, RegistrarRedeemer, TLDRegisterDatum,
}
use utils.{
  all_burned, check_output_exist, create_reference_token_tn,
  get_script_hash_from_address, policy_id_present_in_outputs, quantity_is_one,
  single_name_of_policy_id, verify_tld_signature,
}

// A registrar registers a handshake tld on cardano.
// - 1. He puts a `TLDRegisterDatum on chain which consists of the tld, handshake owner public key and a number.
//      The number is the minted amount of tld references tokens which starts with 0.
// - 2. The tld owner mints tld reference tokens where slds and records are attached.
// - 3. A registrar can burn a tld only if all tld reference tokens are burned.

validator tld_registrar(
  registrar_hns_key: ByteArray,
  stake_cred: StakeCredential,
) {
  spend(
    datum_opt: Option<TLDRegisterDatum>,
    redeemer: RegistrarRedeemer,
    output_reference: OutputReference,
    tx: Transaction,
  ) {
    when redeemer is {
      RegistrarAction { registrar_signature, tld_reference_policy_id } -> {
        expect Some(TLDRegisterDatum { tld, minted, .. }) = datum_opt
        let Transaction { inputs, outputs, .. } = tx
        expect Some(own_input) = find_input(inputs, output_reference)
        let own_address = own_input.output.address
        let own_policy_id = get_script_hash_from_address(own_address)
        let onw_input_token =
          quantity_is_one(
            own_input.output.value,
            own_policy_id,
            tld_reference_policy_id,
          )
        let has_registrar_signed =
          verify_tld_signature(registrar_hns_key, tld, registrar_signature)
        let no_own_token_output =
          !policy_id_present_in_outputs(outputs, own_policy_id)

        let tld_reference_burned = minted == 0
        onw_input_token? && tld_reference_burned? && has_registrar_signed? && no_own_token_output?
      }

      OwnerAction { owner_signature, tld_reference_policy_id } -> {
        expect Some(TLDRegisterDatum { tld, owner_hns_key, minted }) = datum_opt
        let Transaction { inputs, outputs, mint, .. } = tx
        expect Some(own_input) = find_input(inputs, output_reference)
        let own_address = own_input.output.address
        let own_policy_id = get_script_hash_from_address(own_address)
        let onw_input_token =
          quantity_is_one(
            own_input.output.value,
            own_policy_id,
            tld_reference_policy_id,
          )

        let tld_r_tn = create_reference_token_tn(tld)

        let tld_reference_mint_am =
          quantity_of(mint, tld_reference_policy_id, tld_r_tn)
        let has_owner_signed =
          if minted == 0 {
            verify_tld_signature(owner_hns_key, tld, owner_signature)
          } else {
            True
          }
        let new_minted =
          if !(tld_reference_mint_am == 0) {
            minted + tld_reference_mint_am
          } else {
            fail
          }
        let registration_datum =
          InlineDatum(TLDRegisterDatum(tld, owner_hns_key, new_minted))
        let output_exists =
          check_output_exist(
            outputs,
            own_policy_id,
            tld_reference_policy_id,
            own_address,
            registration_datum,
          )
        onw_input_token? && has_owner_signed? && output_exists?
      }

      _ -> fail
    }
  }

  mint(redeemer: RegistrarRedeemer, policy_id: PolicyId, tx: Transaction) {
    when redeemer is {
      RegisterTLD { tld, owner, registrar_signature, tld_reference_policy_id } -> {
        let Transaction { outputs, mint, .. } = tx
        let is_single_mint =
          single_name_of_policy_id(mint, policy_id, tld_reference_policy_id, 1)
        let has_registrar_signed =
          verify_tld_signature(registrar_hns_key, tld, registrar_signature)
        let own_address = Address(Script(policy_id), Some(stake_cred))
        let registration_datum = InlineDatum(TLDRegisterDatum(tld, owner, 0))

        let output_exists =
          check_output_exist(
            outputs,
            policy_id,
            tld_reference_policy_id,
            own_address,
            registration_datum,
          )
        has_registrar_signed? && is_single_mint? && output_exists?
      }
      RegistrarAction { .. } -> {
        let Transaction { mint, .. } = tx
        let is_burning = all_burned(mint, policy_id)
        is_burning?
      }
      _ -> fail
    }
  }

  else(_) {
    fail
  }
}
