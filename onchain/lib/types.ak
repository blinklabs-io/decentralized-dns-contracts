use cardano/assets.{PolicyId}

pub type TLDRegisterDatum {
  // top level domain on handshake
  tld: ByteArray,
  // tld owner handshake public key
  owner_hns_key: ByteArray,
  // amount tld reference tokens minted
  minted: Int,
}

pub type RegistrarRedeemer {
  RegisterTLD {
    tld: ByteArray,
    owner: ByteArray,
    registrar_signature: ByteArray,
    tld_reference_policy_id: PolicyId,
  }
  RegistrarAction {
    registrar_signature: ByteArray,
    tld_reference_policy_id: PolicyId,
  }
  OwnerAction { owner_signature: ByteArray, tld_reference_policy_id: PolicyId }
}

pub type DNSRecord {
  lhs: ByteArray,
  ttl: Option<Int>,
  rtype: ByteArray,
  rdata: ByteArray,
}

pub type TLDReferenceDatum {
  // top level domain on handshake
  tld: ByteArray,
  // tld records
  records: List<DNSRecord>,
  // slds
  slds: List<ByteArray>,
  // next sld (link), if datum gets too big
  next: ByteArray,
}

pub type TLDReferenceAction {
  InitRemoveReference
  MintAdditionalReference
  SpendReference
  BurnReference
}
