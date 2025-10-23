# Handshake Domain Ownership Validation on Cardano

## Milestone Achievement Summary

We have successfully implemented a comprehensive ownership validation system that bridges Handshake domains to the Cardano blockchain. This system provides both initial cryptographic verification and ongoing token-based authorization for Handshake domain owners.

## Method to Validate Ownership of a Handshake Domain on Cardano

Our validation method employs a **dual-signature cryptographic verification system** implemented through two interconnected Aiken smart contract validators:

### 1. [Registrar Validation Layer](../../onchain/validators/tld_registration/tld_registrar.ak)

The `tld_registrar` validator serves as the trust anchor between Handshake and Cardano. It validates domain ownership through:

- **Registrar Signature Verification**: A trusted registrar signs the TLD registration, proving they have authority to bridge Handshake domains onto Cardano
- **Owner Signature Verification**: The actual Handshake domain owner provides a cryptographic signature using their Handshake private key (`owner_hns_key`)

The validation function `verify_tld_signature(owner_hns_key, tld, owner_signature)` cryptographically proves that:
- The signature was created by the holder of the private key corresponding to the Handshake domain's public key
- The signature is bound specifically to the TLD being registered
- The signer has legitimate ownership of the Handshake domain

### 2. [Token-Based Authorization Layer](../../onchain/validators/tld_registration/tld_reference.ak)

After initial cryptographic validation, the system transitions to a more efficient token-based model through the `tld_reference` validator:

- **User Token Issuance**: Upon first validation, the owner receives a unique NFT (user token) tied to their TLD
- **Reference Token System**: Additional reference tokens can be minted for managing subdomains and DNS records
- **Continuous Authorization**: Subsequent operations require possession of the user token rather than repeated signature verification

This approach combines the security of cryptographic proofs with the efficiency and flexibility of Cardano's native token system.

## Working Validation Method for Handshake Domain Ownership

Our implementation provides a complete, functional validation workflow:

### Phase 1: Initial Registration

1. **Domain Owner Preparation**: The Handshake domain owner generates a cryptographic signature proving their ownership
2. **Registrar Processing**: The registrar validates the signature and initiates registration by calling the `RegisterTLD` action
3. **On-Chain Registration**: A `TLDRegisterDatum` is created containing:
   - The TLD name
   - The owner's Handshake public key (`owner_hns_key`)
   - A minting counter (initialized to 0)
4. **NFT Minting**: A registrar NFT is minted and locked in the contract, serving as the registration record

### Phase 2: Owner Activation

1. **First-Time Signature Requirement**: When `minted == 0`, the owner must provide their Handshake signature through the `OwnerAction` redeemer
2. **Reference Token Initialization**: The owner triggers `InitRemoveReference` to mint:
   - One TLD reference token
   - One user token (the ownership credential)
3. **Datum Creation**: A `TLDReferenceDatum` is created with:
   - The TLD name
   - An empty subdomain list (`slds: []`)
   - A linked list pointer (`next: ""`)

### Phase 3: Ongoing Operations

Once activated, the owner can perform operations by holding the user token, without requiring additional Handshake signatures:

**Spend Reference**: Modify the subdomain list while maintaining the reference token
- Validates user token presence: `single_token_in_inputs(inputs, own_policy_id, create_user_token_tn(tld))`
- Allows adding/removing subdomains
- Ensures data integrity (sorted, unique SLD lists)

**Mint Additional Reference**: Split domains across multiple UTxOs for better scalability
- Creates two new reference token outputs
- Distributes subdomains between them
- Maintains linked list structure via `next` pointers

**Burn Reference**: Consolidate multiple references back into one
- Merges subdomain lists from two inputs
- Produces single output with combined data
- Maintains list continuity

### Phase 4: Deregistration

1. **Burn All References**: Owner must burn all TLD reference tokens
2. **Final Burn**: When `minted == 1` (last token), the registrar can execute `RegistrarAction`
3. **Complete Removal**: The registrar NFT is burned, removing the TLD registration from Cardano

## Key Features of Our Implementation

### Security Properties

- **Cryptographic Proof**: Initial ownership requires valid Handshake signature verification
- **Single Validation**: Signature checking only happens once, reducing computational overhead
- **Token Gating**: All subsequent operations are gated by NFT possession
- **Registrar Oversight**: Trusted registrar prevents fraudulent domain claims

### Efficiency Innovations

- **Verify Once, Token Forever**: After initial signature validation, the system uses lightweight token checks
- **Delegatable Ownership**: User tokens can be transferred, enabling ownership changes without re-signing
- **Scalable Architecture**: Reference tokens can be split across multiple UTxOs for managing large subdomain lists
- **Linked List Structure**: Efficient subdomain tracking using the `next` pointer for ordered traversal

### Practical Capabilities

Our validation system enables Handshake domain owners to:
- Prove legitimate ownership through cryptographic signatures
- Register their domains on Cardano with verifiable credentials
- Manage subdomains and DNS records through on-chain datums
- Transfer or delegate ownership via token transfers
- Scale their domain management across multiple UTxOs
- Eventually deregister domains when all references are burned

## Technical Implementation Details

The validation mechanism is implemented across two validators:

**tld_registrar.ak**: Handles initial registration and signature verification
**tld_reference.ak**: Manages reference tokens and subdomain operations

Both validators work in concert, with the registrar validator creating the initial trust anchor and the reference validator providing the operational layer for domain management.

The implementation has been validated through comprehensive Aiken unit tests that verify:
- Correct signature validation logic
- Proper token minting and burning flows
- Datum integrity across all operations
- Edge case handling and security constraints

## Conclusion

We have successfully delivered a production-ready validation method that cryptographically proves Handshake domain ownership on Cardano. The system combines the security of signature-based verification with the efficiency of token-based authorization, creating a practical bridge between the Handshake and Cardano ecosystems.

The validators are implemented, unit tested, and ready for deployment, enabling Handshake domain owners to leverage their domains on the Cardano blockchain.