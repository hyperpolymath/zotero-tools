// Fogbinder Cryptography WASM Module
// License: MIT OR AGPL-3.0 (with Palimpsest)
// Post-quantum cryptography implementation

use wasm_bindgen::prelude::*;

// ============================================================================
// Ed448 Digital Signatures
// ============================================================================

#[wasm_bindgen]
pub struct Ed448KeyPair {
    public_key: Vec<u8>,  // 57 bytes
    secret_key: Vec<u8>,  // 57 bytes
}

#[wasm_bindgen]
impl Ed448KeyPair {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Self {
        // TODO: Implement Ed448 key generation
        Self {
            public_key: vec![0u8; 57],
            secret_key: vec![0u8; 57],
        }
    }

    #[wasm_bindgen(getter)]
    pub fn public_key(&self) -> Vec<u8> {
        self.public_key.clone()
    }

    #[wasm_bindgen(getter)]
    pub fn secret_key(&self) -> Vec<u8> {
        self.secret_key.clone()
    }
}

#[wasm_bindgen]
pub fn ed448_sign(secret_key: &[u8], message: &[u8]) -> Vec<u8> {
    // TODO: Implement Ed448 signing
    vec![0u8; 114] // 114 bytes signature
}

#[wasm_bindgen]
pub fn ed448_verify(public_key: &[u8], message: &[u8], signature: &[u8]) -> bool {
    // TODO: Implement Ed448 verification
    true
}

// ============================================================================
// SHAKE256 Hash Function
// ============================================================================

#[wasm_bindgen]
pub fn shake256_hash(data: &[u8], output_length: usize) -> Vec<u8> {
    use sha3::{Shake256, digest::{Update, ExtendableOutput, XofReader}};

    let mut hasher = Shake256::default();
    hasher.update(data);
    let mut reader = hasher.finalize_xof();

    let mut output = vec![0u8; output_length];
    reader.read(&mut output);

    output
}

// ============================================================================
// BLAKE3 Hash Function
// ============================================================================

#[wasm_bindgen]
pub fn blake3_hash(data: &[u8]) -> Vec<u8> {
    blake3::hash(data).as_bytes().to_vec()
}

// ============================================================================
// Combined Hash (Belt-and-Suspenders)
// ============================================================================

#[wasm_bindgen]
pub fn double_hash(data: &[u8]) -> Vec<u8> {
    let shake = shake256_hash(data, 32);
    let blake = blake3_hash(data);

    shake.iter()
        .zip(blake.iter())
        .map(|(s, b)| s ^ b)
        .collect()
}

// ============================================================================
// Kyber-1024 Post-Quantum KEM
// ============================================================================

#[wasm_bindgen]
pub struct KyberKeyPair {
    public_key: Vec<u8>,   // 1568 bytes
    secret_key: Vec<u8>,   // 3168 bytes
}

#[wasm_bindgen]
impl KyberKeyPair {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Self {
        use pqcrypto_kyber::kyber1024;
        use pqcrypto_traits::kem::PublicKey as _;
        use pqcrypto_traits::kem::SecretKey as _;


        let (pk, sk) = kyber1024::keypair();

        Self {
            public_key: pk.as_bytes().to_vec(),
            secret_key: sk.as_bytes().to_vec(),
        }
    }

    #[wasm_bindgen(getter)]
    pub fn public_key(&self) -> Vec<u8> {
        self.public_key.clone()
    }

    #[wasm_bindgen(getter)]
    pub fn secret_key(&self) -> Vec<u8> {
        self.secret_key.clone()
    }
}

#[wasm_bindgen]
pub struct KyberCiphertext {
    ciphertext: Vec<u8>,      // 1568 bytes
    shared_secret: Vec<u8>,   // 32 bytes
}

#[wasm_bindgen]
impl KyberCiphertext {
    #[wasm_bindgen(getter)]
    pub fn ciphertext(&self) -> Vec<u8> {
        self.ciphertext.clone()
    }

    #[wasm_bindgen(getter)]
    pub fn shared_secret(&self) -> Vec<u8> {
        self.shared_secret.clone()
    }
}

#[wasm_bindgen]
pub fn kyber1024_encapsulate(public_key: &[u8]) -> Result<KyberCiphertext, JsValue> {
    use pqcrypto_kyber::kyber1024;
    use pqcrypto_traits::kem::{PublicKey, SharedSecret, Ciphertext as _};


    let pk = kyber1024::PublicKey::from_bytes(public_key)
        .map_err(|_| JsValue::from_str("Invalid public key"))?;

    let (ss, ct) = kyber1024::encapsulate(&pk);

    Ok(KyberCiphertext {
        ciphertext: ct.as_bytes().to_vec(),
        shared_secret: ss.as_bytes().to_vec(),
    })
}

#[wasm_bindgen]
pub fn kyber1024_decapsulate(secret_key: &[u8], ciphertext: &[u8]) -> Result<Vec<u8>, JsValue> {
    use pqcrypto_kyber::kyber1024;
    use pqcrypto_traits::kem::{SecretKey, SharedSecret, Ciphertext};


    let sk = kyber1024::SecretKey::from_bytes(secret_key)
        .map_err(|_| JsValue::from_str("Invalid secret key"))?;

    let ct = kyber1024::Ciphertext::from_bytes(ciphertext)
        .map_err(|_| JsValue::from_str("Invalid ciphertext"))?;

    let ss = kyber1024::decapsulate(&ct, &sk);

    Ok(ss.as_bytes().to_vec())
}

// ============================================================================
// Argon2id Password Hashing
// ============================================================================

#[wasm_bindgen]
pub struct Argon2Params {
    pub memory_kib: u32,
    pub iterations: u32,
    pub parallelism: u32,
    pub output_length: usize,
}

#[wasm_bindgen]
impl Argon2Params {
    #[wasm_bindgen(constructor)]
    pub fn new() -> Self {
        Self {
            memory_kib: 65536,  // 64 MB
            iterations: 3,
            parallelism: 4,
            output_length: 32,
        }
    }
}

#[wasm_bindgen]
pub fn argon2id_hash(password: &[u8], salt: &[u8], params: &Argon2Params) -> Vec<u8> {
    use argon2::{Argon2, Algorithm, Version, ParamsBuilder};

    let argon2_params = ParamsBuilder::new()
        .m_cost(params.memory_kib)
        .t_cost(params.iterations)
        .p_cost(params.parallelism)
        .output_len(params.output_length)
        .build()
        .expect("Invalid Argon2 parameters");

    let argon2 = Argon2::new(Algorithm::Argon2id, Version::V0x13, argon2_params);

    let mut output = vec![0u8; params.output_length];
    argon2.hash_password_into(password, salt, &mut output)
        .expect("Argon2 hashing failed");

    output
}

// ============================================================================
// ChaCha20-Poly1305 AEAD
// ============================================================================

#[wasm_bindgen]
pub fn chacha20_encrypt(key: &[u8], nonce: &[u8], plaintext: &[u8]) -> Result<Vec<u8>, JsValue> {
    use chacha20poly1305::{
        aead::{Aead, KeyInit},
        ChaCha20Poly1305, Nonce,
    };

    if key.len() != 32 {
        return Err(JsValue::from_str("Key must be 32 bytes"));
    }
    if nonce.len() != 12 {
        return Err(JsValue::from_str("Nonce must be 12 bytes"));
    }

    let cipher = ChaCha20Poly1305::new_from_slice(key)
        .map_err(|e| JsValue::from_str(&format!("Failed to create cipher: {}", e)))?;

    let nonce_array = Nonce::from_slice(nonce);

    let ciphertext = cipher
        .encrypt(nonce_array, plaintext)
        .map_err(|e| JsValue::from_str(&format!("Encryption failed: {}", e)))?;

    Ok(ciphertext)
}

#[wasm_bindgen]
pub fn chacha20_decrypt(key: &[u8], nonce: &[u8], ciphertext: &[u8]) -> Result<Vec<u8>, JsValue> {
    use chacha20poly1305::{
        aead::{Aead, KeyInit},
        ChaCha20Poly1305, Nonce,
    };

    if key.len() != 32 {
        return Err(JsValue::from_str("Key must be 32 bytes"));
    }
    if nonce.len() != 12 {
        return Err(JsValue::from_str("Nonce must be 12 bytes"));
    }

    let cipher = ChaCha20Poly1305::new_from_slice(key)
        .map_err(|e| JsValue::from_str(&format!("Failed to create cipher: {}", e)))?;

    let nonce_array = Nonce::from_slice(nonce);

    let plaintext = cipher
        .decrypt(nonce_array, ciphertext)
        .map_err(|e| JsValue::from_str(&format!("Decryption failed: {}", e)))?;

    Ok(plaintext)
}

// ============================================================================
// Strong Prime Generation
// ============================================================================

#[wasm_bindgen]
pub fn generate_strong_prime(bits: usize) -> Vec<u8> {
    // TODO: Implement strong (safe) prime generation
    // A strong prime p has (p-1)/2 also prime
    vec![0u8; bits / 8]
}

// ============================================================================
// Tests
// ============================================================================

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_shake256() {
        let data = b"test data";
        let hash = shake256_hash(data, 32);
        assert_eq!(hash.len(), 32);

        // Same input should produce same output
        let hash2 = shake256_hash(data, 32);
        assert_eq!(hash, hash2);
    }

    #[test]
    fn test_blake3() {
        let data = b"test data";
        let hash = blake3_hash(data);
        assert_eq!(hash.len(), 32);

        // Same input should produce same output
        let hash2 = blake3_hash(data);
        assert_eq!(hash, hash2);
    }

    #[test]
    fn test_double_hash() {
        let data = b"test data";
        let hash = double_hash(data);
        assert_eq!(hash.len(), 32);

        // Different from individual hashes
        let shake = shake256_hash(data, 32);
        let blake = blake3_hash(data);
        assert_ne!(hash, shake);
        assert_ne!(hash, blake);
    }

    #[test]
    fn test_argon2id() {
        let password = b"correct horse battery staple";
        let salt = b"random salt 1234";
        let params = Argon2Params::new();
        let hash = argon2id_hash(password, salt, &params);
        assert_eq!(hash.len(), 32);

        // Same input should produce same output
        let hash2 = argon2id_hash(password, salt, &params);
        assert_eq!(hash, hash2);

        // Different password should produce different hash
        let hash3 = argon2id_hash(b"wrong password", salt, &params);
        assert_ne!(hash, hash3);
    }

    #[test]
    fn test_chacha20_encrypt_decrypt() {
        let key = [0u8; 32];
        let nonce = [1u8; 12];
        let plaintext = b"Hello, post-quantum world!";

        let ciphertext = chacha20_encrypt(&key, &nonce, plaintext)
            .expect("Encryption failed");

        // Ciphertext should be plaintext + 16 byte tag
        assert_eq!(ciphertext.len(), plaintext.len() + 16);

        let decrypted = chacha20_decrypt(&key, &nonce, &ciphertext)
            .expect("Decryption failed");

        assert_eq!(decrypted, plaintext);
    }

    #[test]
    fn test_chacha20_wrong_key_fails() {
        let key1 = [0u8; 32];
        let key2 = [1u8; 32];
        let nonce = [1u8; 12];
        let plaintext = b"Secret message";

        let ciphertext = chacha20_encrypt(&key1, &nonce, plaintext)
            .expect("Encryption failed");

        // Decryption with wrong key should fail
        let result = chacha20_decrypt(&key2, &nonce, &ciphertext);
        assert!(result.is_err());
    }

    #[test]
    fn test_kyber1024_keypair_generation() {
        let keypair = KyberKeyPair::new();

        assert_eq!(keypair.public_key().len(), 1568);
        assert_eq!(keypair.secret_key().len(), 3168);
    }

    #[test]
    fn test_kyber1024_encapsulation_decapsulation() {
        use pqcrypto_kyber::kyber1024;
        use pqcrypto_traits::kem::PublicKey as _;
        use pqcrypto_traits::kem::SecretKey as _;

        let (pk, sk) = kyber1024::keypair();

        let encap_result = kyber1024_encapsulate(pk.as_bytes())
            .expect("Encapsulation failed");

        let shared_secret_1 = encap_result.shared_secret();
        assert_eq!(shared_secret_1.len(), 32);

        let shared_secret_2 = kyber1024_decapsulate(
            sk.as_bytes(),
            &encap_result.ciphertext()
        ).expect("Decapsulation failed");

        // Both sides should derive the same shared secret
        assert_eq!(shared_secret_1, shared_secret_2);
    }

    #[test]
    fn test_kyber1024_wrong_key_different_secret() {
        use pqcrypto_kyber::kyber1024;
        use pqcrypto_traits::kem::PublicKey as _;
        use pqcrypto_traits::kem::SecretKey as _;

        let (pk1, _sk1) = kyber1024::keypair();
        let (_pk2, sk2) = kyber1024::keypair();

        let encap_result = kyber1024_encapsulate(pk1.as_bytes())
            .expect("Encapsulation failed");

        // Decapsulating with wrong secret key should produce different shared secret
        let shared_secret_wrong = kyber1024_decapsulate(
            sk2.as_bytes(),
            &encap_result.ciphertext()
        ).expect("Decapsulation succeeded (but wrong secret)");

        assert_ne!(encap_result.shared_secret(), shared_secret_wrong);
    }
}
