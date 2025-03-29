# secp256k1
secp256k1 is an elliptic curve used in cryptography, primarily by Bitcoin, Ethereum, and Handshake (HNS) for digital signatures and key generation. It is part of the Standards for Efficient Cryptography (SEC) curves published by SECG.

1. #### The Basics of Elliptic Curves
Elliptic curves are mathematical structures defined by equations of the form:
- y²=x³+ax+b

For secp256k1, the equation is:
- y²=x³+7

No "a" term (unlike many other curves), making it simpler.

Uses a 256-bit prime field, meaning all calculations are done modulo a prime number.

2. #### secp256k1 Parameters
- Curve Equation	
    - y²=x³+7
- Prime Modulus (p)	
    - 2²⁵⁶−2³²−977
- Order (n)	
    - 2²⁵⁶−432420386565659656852420866394968145599
- Generator Point (G)
    - (x,y) defined in the standard
- Field	
    - Finite field 𝐹𝑝
​
- These parameters define how points on the curve behave, ensuring security and efficiency for cryptographic applications.

3. #### Key Operations in secp256k1
    - 1. **Private Key Generation**:

        A 256-bit random number (within the order of the curve) is chosen as the private key:

            𝑘=random_value(nonce) mod n

    - 2. **Public Key Generation**:

        The public key is derived using elliptic curve multiplication:

            𝑃=𝑘*𝐺P

        where G is the generator point and k is the private key.
        Public key = Private key × Generator Point

        This operation is one-way!

        You can compute P from k, but not vice versa (this is what makes it secure).

    - 3. **Digital Signatures (ECDSA)**

        secp256k1 is used in ECDSA (Elliptic Curve Digital Signature Algorithm) to sign messages.

        The signature consists of two values (r, s), which are computed using:

            r=(kG)𝑥 mod n

            𝑠=𝑘⁻¹(𝐻(𝑚)+𝑟𝑑) mod 𝑛
        where H(m) is the hash of the message, d is the private key and
        k is a random nonce.

## secp256k1 in Cardano smart contracts

Since Plutus V3, Cardano now includes built-in support for secp256k1 signature verification. This means you can:

- Verify secp256k1 signatures inside a smart contract.

- Validate Bitcoin, or Handshake transactions in Cardano-based dApps.

- Enable cross-chain interoperability (e.g., BTC<>ADA swaps, Ethereum<>Cardano bridges).

#### in [aiken](https://github.com/aiken-lang/stdlib/blob/2.2.0/lib/aiken/crypto.ak#L121-L127):

```haskell
pub fn verify_ecdsa_signature(
  key: VerificationKey,
  msg: ByteArray,
  sig: Signature,
) -> Bool {
  builtin.verify_ecdsa_secp256k1_signature(key, msg, sig)
}
```
- Explanation:
**key**: The secp256k1 public key used for verification.
**msg**: The message that was signed.
**sig**: The secp256k1 signature.
Returns **true** if the signature is valid, otherwise false.

#### How to Use This in a Smart Contract
- User signs a message with secp256k1 (e.g., Bitcoin or Handshake user signs with their private key).

- Submit the message, signature, and public key to the Cardano smart contract.

- Aiken contract verifies the signature using verify_ecdsa_signature.

- If valid, contract executes the logic (e.g., releases ADA, interacts with other contracts).

