use aiken/builtin.{head_list}
use aiken/collection/dict.{get, size}
use aiken/collection/list.{all, concat, foldl, has, push, sort, unique}
use aiken/option.{is_none}
use aiken/primitive/bytearray.{compare}
use cardano/address.{Address, Script, StakeCredential}
use cardano/assets.{PolicyId, quantity_of, tokens}
use cardano/transaction.{Output, OutputReference, Transaction, find_input}
use types.{
  BurnReference, InitRemoveReference, MintAdditionalReference, SpendReference,
  TLDReferenceAction, TLDReferenceDatum, TLDRegisterDatum,
}
use utils.{
  create_reference_token_tn, create_user_token_tn,
  filter_input_with_single_token, filter_single_token_in_outputs,
  get_inline_datum_output, get_script_hash_from_address, quantity_is_one,
  single_name_of_policy_id, single_token_in_inputs, two_token_value,
}

validator tld_reference(
  tld_registrar_policy_id: PolicyId,
  stake_cred: StakeCredential,
) {
  spend(
    datum_opt: Option<TLDReferenceDatum>,
    redeemer: TLDReferenceAction,
    output_reference: OutputReference,
    tx: Transaction,
  ) {
    when redeemer is {
      SpendReference -> {
        let Transaction { inputs, outputs, mint, .. } = tx
        expect Some(TLDReferenceDatum { tld, slds, next, .. }) = datum_opt
        expect Some(own_input) = find_input(inputs, output_reference)
        let own_address = own_input.output.address
        let own_policy_id = get_script_hash_from_address(own_address)
        let tld_r_tn = create_reference_token_tn(tld)
        let own_input_token =
          quantity_is_one(own_input.output.value, own_policy_id, tld_r_tn)
        let user_token_is_present =
          single_token_in_inputs(
            inputs,
            own_policy_id,
            create_user_token_tn(tld),
          )
        let is_minting = quantity_of(mint, own_policy_id, tld_r_tn) > 0
        let is_burning = quantity_of(mint, own_policy_id, tld_r_tn) < 0
        let own_outputs =
          filter_single_token_in_outputs(outputs, own_policy_id, tld_r_tn)
        let output_valid =
          if is_burning {
            False
          } else {
            when own_outputs is {
              [own_output] -> {
                expect TLDReferenceDatum {
                  tld: tld_new,
                  slds: slds_new,
                  next: next_new,
                  ..
                } = get_inline_datum_output(own_output)
                let output_datum_correct =
                  (next_new == next)? && (tld_new == tld)? && (slds_new == unique(
                    sort(slds_new, compare),
                  ))? && all(slds, fn(sld) { has(slds_new, sld) })?
                let output_is_correct =
                  two_token_value(own_output.value)? && is_none(
                    own_output.reference_script,
                  )? && (own_output.address == own_address)? && output_datum_correct?
                output_is_correct?
              }
              _ -> False
            }
          }

        let valid_action =
          when (is_minting, is_burning, output_valid) is {
            (True, False, False) -> True
            (False, True, False) -> True
            (False, False, True) -> True
            _ -> False
          }

        own_input_token? && user_token_is_present? && valid_action?
      }

      _ -> fail
    }
  }

  mint(redeemer: TLDReferenceAction, policy_id: PolicyId, tx: Transaction) {
    when redeemer is {
      InitRemoveReference -> {
        let Transaction { inputs, outputs, mint, .. } = tx
        expect [tld_refrence_input] =
          filter_input_with_single_token(
            inputs,
            tld_registrar_policy_id,
            policy_id,
          )
        expect TLDRegisterDatum { tld, minted, .. } =
          get_inline_datum_output(tld_refrence_input.output)
        let mint_tn_ams = tokens(mint, policy_id)
        let tld_r_tn = create_reference_token_tn(tld)
        let correct_mint =
          (size(mint_tn_ams) == 2)? && (get(mint_tn_ams, tld_r_tn) == Some(1))? && (get(
            mint_tn_ams,
            create_user_token_tn(tld),
          ) == Some(1))?

        let is_first_mint =
          if minted == 0 {
            expect [own_output] =
              filter_single_token_in_outputs(outputs, policy_id, tld_r_tn)
            expect TLDReferenceDatum { tld: tld_ref, slds, next, .. } =
              get_inline_datum_output(own_output)
            let output_datum_correct =
              (next == "")? && (tld_ref == tld)? && (slds == [])?
            let own_address = Address(Script(policy_id), Some(stake_cred))
            let output_is_correct =
              two_token_value(own_output.value)? && is_none(
                own_output.reference_script,
              )? && (own_output.address == own_address)? && output_datum_correct?
            output_is_correct?
          } else {
            False
          }
        let is_last = (minted == 1)?
        let correct_burn =
          (size(mint_tn_ams) == 2)? && (get(mint_tn_ams, tld_r_tn) == Some(-1))? && (get(
            mint_tn_ams,
            create_user_token_tn(tld),
          ) == Some(-1))?
        correct_mint? && is_first_mint? || correct_burn? && is_last?
      }
      MintAdditionalReference -> {
        let Transaction { inputs, outputs, mint, .. } = tx
        expect [ref_input] =
          filter_input_with_single_token(
            inputs,
            tld_registrar_policy_id,
            policy_id,
          )
        expect TLDRegisterDatum { tld, minted, .. } =
          get_inline_datum_output(ref_input.output)
        let tld_r_tn = create_reference_token_tn(tld)
        let correct_mint =
          single_name_of_policy_id(mint, policy_id, tld_r_tn, 1)
        let not_first = !(minted == 0)?
        expect [own_input] =
          filter_input_with_single_token(inputs, policy_id, tld_r_tn)
        expect TLDReferenceDatum { tld: tld_own, slds, .. } =
          get_inline_datum_output(own_input.output)
        let own_address = Address(Script(policy_id), Some(stake_cred))
        expect [own_output_dat1,
          own_output_dat2] =
          foldl(
            outputs,
            [],
            fn(output, all) {
              if quantity_is_one(output.value, policy_id, tld_r_tn) {
                if two_token_value(output.value)? && is_none(
                  output.reference_script,
                )? && (output.address == own_address)? {
                  expect dat: TLDReferenceDatum =
                    get_inline_datum_output(output)
                  push(all, dat)
                } else {
                  fail
                }
              } else {
                all
              }
            },
          )
        let tld_is_same = tld_own == tld
        let all_new_slds = concat(own_output_dat1.slds, own_output_dat2.slds)
        let all_slds_still_exist = all(slds, fn(sld) { has(all_new_slds, sld) })
        let slds_sorted_unique =
          (unique(sort(own_output_dat1.slds, compare)) == own_output_dat1.slds)? && (unique(
            sort(own_output_dat2.slds, compare),
          ) == own_output_dat2.slds)?
        let next_is_set =
          if own_output_dat1.next == "" {
            head_list(own_output_dat1.slds) == own_output_dat2.next
          } else if own_output_dat2.next == "" {
            head_list(own_output_dat2.slds) == own_output_dat1.next
          } else {
            fail @"next not set"
          }
        correct_mint? && not_first? && tld_is_same? && all_slds_still_exist? && slds_sorted_unique? && next_is_set?
      }

      BurnReference -> {
        let Transaction { inputs, outputs, mint, .. } = tx
        expect [ref_input] =
          filter_input_with_single_token(
            inputs,
            tld_registrar_policy_id,
            policy_id,
          )
        expect TLDRegisterDatum { tld, minted, .. } =
          get_inline_datum_output(ref_input.output)
        let tld_r_tn = create_reference_token_tn(tld)
        expect [own_input1,
          own_input2] =
          filter_input_with_single_token(inputs, policy_id, tld_r_tn)
        expect own_input_dat1: TLDReferenceDatum =
          get_inline_datum_output(own_input1.output)
        expect own_input_dat2: TLDReferenceDatum =
          get_inline_datum_output(own_input2.output)
        let own_address = Address(Script(policy_id), Some(stake_cred))
        expect [own_output] =
          filter_single_token_in_outputs(outputs, policy_id, tld_r_tn)
        let own_output_valid =
          two_token_value(own_output.value)? && is_none(
            own_output.reference_script,
          )? && (own_output.address == own_address)?
        expect TLDReferenceDatum { tld: tld_new, slds, next, .. } =
          get_inline_datum_output(own_output)
        let correct_mint =
          single_name_of_policy_id(mint, policy_id, tld_r_tn, -1)
        let not_last = (minted == 1)?
        let tld_same = tld == tld_new
        let next_is_valid =
          if own_input_dat1.next == head_list(own_input_dat2.slds) {
            next == own_input_dat2.next
          } else if own_input_dat2.next == head_list(own_input_dat1.slds) {
            next == own_input_dat1.next
          } else {
            fail
          }
        let all_old_slds = concat(own_input_dat1.slds, own_input_dat2.slds)
        let all_slds_present = all(all_old_slds, fn(n) { has(slds, n) })
        correct_mint? && not_last? && own_output_valid? && tld_same? && next_is_valid? && all_slds_present?
      }

      _ -> fail
    }
  }

  else(_) {
    fail
  }
}
