const bcrypto = require('bcrypto');
const { SHA256, BLAKE2b } = bcrypto;
const secp256k1 = bcrypto.secp256k1;
const random = bcrypto.random;
const fs = require('fs');

// Generate a valid private key
let privKey;
do {
  privKey = random.randomBytes(32);
} while (!secp256k1.privateKeyVerify(privKey));

// Public key (compressed)
const pubKey = secp256k1.publicKeyCreate(privKey, true);

// Message and hash
const message = Buffer.from('hello-handshake', 'utf8');
//const hash = SHA256.digest(message);
const hash = BLAKE2b.digest(message);

// Sign the message
const [signature, recovery] = secp256k1.signRecoverable(hash, privKey);

// Signature without recovery byte
const sig64 = signature; // 64 bytes: r||s

// Prepare the data to be written to a JSON file
const output = {
  privateKey: privKey.toString('hex'),
  publicKey: pubKey.toString('hex'),
  messageHash: hash.toString('hex'),
  signature: sig64.toString('hex')
};

// Write the output to a JSON file
fs.writeFileSync('secp256k1_output.json', JSON.stringify(output, null, 2));

console.log('Data written to secp256k1_output.json');
