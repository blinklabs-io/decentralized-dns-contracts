# Cardano vs. Handshake

1. ## Smart Contract Capabilities

- **Handshake**
    - Limited scripting functionality (based on Bitcoin’s UTXO model).

    - No Turing-complete smart contracts (only basic scripts like multi-sig).

    - Used primarily for domain name auctions and DNS management.

- **Cardano**
    - Full smart contract support.

    - Uses Extended UTXO (eUTXO) model.

    - Supports multi-asset transactions (native tokens).

2. ## Address Format & Structure

- **Handshake (HNS)**
    - Format: Handshake addresses follow the Bitcoin-like Base58Check encoding.

        Example: hs1qv6u6gy2pryq8r9p2r8k4h5nx4yzltvfnf4q96c

    - Structure:

        - hs1 → Bech32 prefix (similar to SegWit in Bitcoin).

        - qv6u6gy2... → Encoded public key hash.

    - Types of Addresses:

        - P2PKH (Pay-to-PubKey-Hash) – Uses hashed public keys.

        - P2SH (Pay-to-Script-Hash) – For multi-signature & scripts.

- **Cardano (ADA)**
    - Format: Uses Base58 or Bech32 (depending on Shelley or Byron era).

        Example: addr1q9cz4v6u6gy2pryq8r9p2r8k4h5nx4yzltvfnf4q96c

    - Structure:

        addr1 → Prefix indicating mainnet address.

        The rest is derived from the public key hash using Ed25519 cryptography.

3. ## Signature Algorithm

- **Handshake (HNS) – ECDSA (secp256k1)**
    - Uses Elliptic Curve Digital Signature Algorithm [(ECDSA)](https://en.wikipedia.org/wiki/Elliptic_Curve_Digital_Signature_Algorithm).

    - The same curve (secp256k1) is used by Bitcoin.

    - The public key is derived from a private key using secp256k1 mathematics.

    - Uses SHA-256 for hashing and RIPEMD-160 for address generation.

- **Cardano (ADA) – EdDSA (Ed25519)**
    - Uses Edwards-curve Digital Signature Algorithm [(EdDSA)](https://en.wikipedia.org/wiki/EdDSA).

    - More secure than ECDSA and resistant to [side-channel](https://en.wikipedia.org/wiki/Side-channel_attack) attacks.

    - Uses Blake2b-224 for hashing (instead of SHA-256).

    - Signatures are deterministic (same input always gives the same signature).

4. ## Key Generation Process
- **Handshake (ECDSA)**
    - Generate a random 256-bit private key.

    - Compute the public key using secp256k1 curve multiplication.

    - Derive the address by hashing the public key with SHA-256 + RIPEMD-160.

- **Cardano (Ed25519)**
    - Generate a 256-bit private key.

    - Compute the public key using the Ed25519 elliptic curve.

    - Derive the address by hashing with Blake2b-224.