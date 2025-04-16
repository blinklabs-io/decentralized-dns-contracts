use aiken/builtin.{verify_ecdsa_secp256k1_signature}
use cardano/assets.{PolicyId}
use cardano/transaction.{Transaction}

// provide public key and signature in redeemer
// does not make much sense but okey for testing signature verification
pub type HNSData {
  hns_vkey: ByteArray,
  hns_signature: ByteArray,
}

// simply verify public key hash signed message to mint token
validator verify_hns_sig(msg: ByteArray) {
  mint(redeemer: HNSData, _policy_id: PolicyId, _self: Transaction) {
    verify_ecdsa_secp256k1_signature(
      redeemer.hns_vkey,
      msg,
      redeemer.hns_signature,
    )
  }

  else(_) {
    fail
  }
}
