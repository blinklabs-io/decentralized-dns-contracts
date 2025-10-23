use cardano/assets.{from_asset, merge}
use cardano/transaction.{Input, Transaction, placeholder}
use constants.{
  registrar_hns_vkey, registrar_signature, stake_cred, tld, tld_owner_signature,
  tld_owner_vkey, tld_reference_cs, tld_registrar_cs,
}
use test_utils.{create_tld_registrar_output, mock_utxo_ref}
use tld_registration/tld_registrar as registrar
use types.{
  OwnerAction, RegisterTLD, RegistrarAction, RegistrarRedeemer, TLDRegisterDatum,
}
use utils.{create_reference_token_tn}

fn tld_registrar_mint(red: RegistrarRedeemer, tx: Transaction) -> Bool {
  registrar.tld_registrar.mint(
    registrar_hns_vkey,
    stake_cred,
    red,
    tld_registrar_cs,
    tx,
  )
}

const tld_mint_succeed_tx =
  Transaction {
    ..placeholder,
    outputs: [create_tld_registrar_output(tld_owner_vkey, 0)],
    mint: from_asset(tld_registrar_cs, tld_reference_cs, 1),
  }

const register_red =
  RegisterTLD(tld, tld_owner_vkey, registrar_signature, tld_reference_cs)

test tld_mint_succeed() {
  tld_registrar_mint(register_red, tld_mint_succeed_tx)
}

test tld_mint_fail1_registrar_signature() fail {
  tld_registrar_mint(
    RegisterTLD(tld, tld_owner_vkey, tld_owner_signature, tld_reference_cs),
    tld_mint_succeed_tx,
  )
}

test tld_mint_fail2_mint() fail {
  tld_registrar_mint(
    register_red,
    Transaction {
      ..tld_mint_succeed_tx,
      mint: from_asset(tld_registrar_cs, tld, 2),
    },
  )
}

fn tld_registrar_spend(
  dat: TLDRegisterDatum,
  red: RegistrarRedeemer,
  tx: Transaction,
) -> Bool {
  registrar.tld_registrar.spend(
    registrar_hns_vkey,
    stake_cred,
    Some(dat),
    red,
    mock_utxo_ref("0", 0),
    tx,
  )
}

const tld_owner_spend_succeed_tx =
  Transaction {
    ..placeholder,
    inputs: [
      Input(
        mock_utxo_ref("0", 0),
        create_tld_registrar_output(tld_owner_vkey, 0),
      ),
    ],
    outputs: [create_tld_registrar_output(tld_owner_vkey, 1)],
    mint: from_asset(tld_reference_cs, create_reference_token_tn(tld), 1),
  }

const tld_owner_spend_succeed_tx2 =
  Transaction {
    ..placeholder,
    inputs: [
      Input(
        mock_utxo_ref("0", 0),
        create_tld_registrar_output(tld_owner_vkey, 1),
      ),
    ],
    outputs: [create_tld_registrar_output(tld_owner_vkey, 0)],
    mint: from_asset(tld_reference_cs, create_reference_token_tn(tld), -1),
  }

const tld_dat = TLDRegisterDatum(tld, tld_owner_vkey, 0)

test tld_owner_spend_succeed1() {
  tld_registrar_spend(
    TLDRegisterDatum(tld, tld_owner_vkey, 1),
    OwnerAction("", tld_reference_cs),
    tld_owner_spend_succeed_tx2,
  )
}

test tld_owner_spend_succeed2() {
  tld_registrar_spend(
    tld_dat,
    OwnerAction(tld_owner_signature, tld_reference_cs),
    tld_owner_spend_succeed_tx,
  )
}

const tld_burn_succeed_tx =
  Transaction {
    ..placeholder,
    inputs: [
      Input(
        mock_utxo_ref("0", 0),
        create_tld_registrar_output(tld_owner_vkey, 1),
      ),
    ],
    mint: from_asset(tld_registrar_cs, tld_reference_cs, -1),
  }

test tld_burn_succed() {
  tld_registrar_spend(
    tld_dat,
    RegistrarAction(registrar_signature, tld_reference_cs),
    tld_burn_succeed_tx,
  ) && tld_registrar_mint(
    RegistrarAction(registrar_signature, tld_reference_cs),
    tld_burn_succeed_tx,
  )
}

test tld_burn_fail1_onw_in_token() fail {
  tld_registrar_spend(
    TLDRegisterDatum("tld", tld_owner_vkey, 1),
    RegistrarAction(registrar_signature, tld_reference_cs),
    tld_burn_succeed_tx,
  ) && tld_registrar_mint(register_red, tld_burn_succeed_tx)
}

test tld_burn_fail2_registrar_signer() fail {
  tld_registrar_spend(
    tld_dat,
    RegistrarAction(registrar_signature, tld_reference_cs),
    tld_burn_succeed_tx,
  ) && tld_registrar_mint(
    RegisterTLD(tld, tld_owner_vkey, tld_owner_signature, tld_reference_cs),
    tld_burn_succeed_tx,
  )
}

test tld_burn_fail3_output() fail {
  let tx =
    Transaction {
      ..tld_burn_succeed_tx,
      outputs: [create_tld_registrar_output(tld_owner_signature, 1)],
    }
  tld_registrar_spend(
    tld_dat,
    RegistrarAction(registrar_signature, tld_reference_cs),
    tx,
  ) && tld_registrar_mint(register_red, tx)
}

test tld_burn_fail4_mint() fail {
  let tx =
    Transaction {
      ..tld_burn_succeed_tx,
      mint: merge(
        from_asset(tld_registrar_cs, tld, -1),
        from_asset(tld_registrar_cs, "tld", 1),
      ),
    }
  tld_registrar_spend(
    tld_dat,
    RegistrarAction(registrar_signature, tld_reference_cs),
    tx,
  ) && tld_registrar_mint(register_red, tx)
}
