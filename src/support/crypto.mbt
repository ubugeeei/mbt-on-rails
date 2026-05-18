///|
/// SHA-256 round constants (FIPS 180-4 §4.2.2).
let sha256_k : FixedArray[UInt] = [
  0x428a2f98U, 0x71374491U, 0xb5c0fbcfU, 0xe9b5dba5U, 0x3956c25bU, 0x59f111f1U, 0x923f82a4U,
  0xab1c5ed5U, 0xd807aa98U, 0x12835b01U, 0x243185beU, 0x550c7dc3U, 0x72be5d74U, 0x80deb1feU,
  0x9bdc06a7U, 0xc19bf174U, 0xe49b69c1U, 0xefbe4786U, 0x0fc19dc6U, 0x240ca1ccU, 0x2de92c6fU,
  0x4a7484aaU, 0x5cb0a9dcU, 0x76f988daU, 0x983e5152U, 0xa831c66dU, 0xb00327c8U, 0xbf597fc7U,
  0xc6e00bf3U, 0xd5a79147U, 0x06ca6351U, 0x14292967U, 0x27b70a85U, 0x2e1b2138U, 0x4d2c6dfcU,
  0x53380d13U, 0x650a7354U, 0x766a0abbU, 0x81c2c92eU, 0x92722c85U, 0xa2bfe8a1U, 0xa81a664bU,
  0xc24b8b70U, 0xc76c51a3U, 0xd192e819U, 0xd6990624U, 0xf40e3585U, 0x106aa070U, 0x19a4c116U,
  0x1e376c08U, 0x2748774cU, 0x34b0bcb5U, 0x391c0cb3U, 0x4ed8aa4aU, 0x5b9cca4fU, 0x682e6ff3U,
  0x748f82eeU, 0x78a5636fU, 0x84c87814U, 0x8cc70208U, 0x90befffaU, 0xa4506cebU, 0xbef9a3f7U,
  0xc67178f2U,
]

///|
fn sha256_initial_state() -> FixedArray[UInt] {
  let h : FixedArray[UInt] = FixedArray::make(8, 0U)
  h[0] = 0x6a09e667U
  h[1] = 0xbb67ae85U
  h[2] = 0x3c6ef372U
  h[3] = 0xa54ff53aU
  h[4] = 0x510e527fU
  h[5] = 0x9b05688cU
  h[6] = 0x1f83d9abU
  h[7] = 0x5be0cd19U
  h
}

///|
fn rotr_u32(value : UInt, count : Int) -> UInt {
  (value >> count) | (value << (32 - count))
}

///|
fn sha256_ch(x : UInt, y : UInt, z : UInt) -> UInt {
  (x & y) ^ (x.lnot() & z)
}

///|
fn sha256_maj(x : UInt, y : UInt, z : UInt) -> UInt {
  (x & y) ^ (x & z) ^ (y & z)
}

///|
fn sha256_big_sigma0(x : UInt) -> UInt {
  rotr_u32(x, 2) ^ rotr_u32(x, 13) ^ rotr_u32(x, 22)
}

///|
fn sha256_big_sigma1(x : UInt) -> UInt {
  rotr_u32(x, 6) ^ rotr_u32(x, 11) ^ rotr_u32(x, 25)
}

///|
fn sha256_small_sigma0(x : UInt) -> UInt {
  rotr_u32(x, 7) ^ rotr_u32(x, 18) ^ (x >> 3)
}

///|
fn sha256_small_sigma1(x : UInt) -> UInt {
  rotr_u32(x, 17) ^ rotr_u32(x, 19) ^ (x >> 10)
}

///|
/// Encodes a Char into its UTF-8 byte sequence appended to `out`.
fn utf8_encode_char(out : Array[UInt], ch : Char) -> Unit {
  let code = ch.to_uint()
  if code < 0x80U {
    out.push(code & 0xffU)
  } else if code < 0x800U {
    out.push(0xc0U | (code >> 6))
    out.push(0x80U | (code & 0x3fU))
  } else if code < 0x10000U {
    out.push(0xe0U | (code >> 12))
    out.push(0x80U | ((code >> 6) & 0x3fU))
    out.push(0x80U | (code & 0x3fU))
  } else {
    out.push(0xf0U | (code >> 18))
    out.push(0x80U | ((code >> 12) & 0x3fU))
    out.push(0x80U | ((code >> 6) & 0x3fU))
    out.push(0x80U | (code & 0x3fU))
  }
}

///|
/// Returns the UTF-8 byte representation of `source` as an array of
/// `UInt` values in the range 0..255.
pub fn utf8_bytes(source : String) -> Array[UInt] {
  let bytes : Array[UInt] = []
  for ch in source {
    utf8_encode_char(bytes, ch)
  }
  bytes
}

///|
/// Concatenates two byte arrays.
fn concat_bytes(left : Array[UInt], right : Array[UInt]) -> Array[UInt] {
  let out : Array[UInt] = []
  for value in left {
    out.push(value)
  }
  for value in right {
    out.push(value)
  }
  out
}

///|
/// Hex-encodes a byte sequence as a lowercase string.
pub fn hex_encode_bytes(bytes : Array[UInt]) -> String {
  let builder = StringBuilder::new()
  for value in bytes {
    builder.write_char(hex_char((value >> 4) & 0xfU))
    builder.write_char(hex_char(value & 0xfU))
  }
  builder.to_string()
}

///|
fn hex_char(value : UInt) -> Char {
  if value < 10U {
    ('0'.to_uint() + value).reinterpret_as_int().to_char().unwrap()
  } else {
    ('a'.to_uint() + value - 10U).reinterpret_as_int().to_char().unwrap()
  }
}

///|
/// Computes the SHA-256 digest of `bytes` and returns the 32-byte
/// result as an array of `UInt` values in the range 0..255.
pub fn sha256_bytes(bytes : Array[UInt]) -> Array[UInt] {
  let original_length = bytes.length()
  let padded : Array[UInt] = []
  for value in bytes {
    padded.push(value)
  }
  padded.push(0x80U)
  while padded.length() % 64 != 56 {
    padded.push(0U)
  }
  let bit_length : UInt64 = original_length.to_uint64() << 3
  let mut shift = 56
  while shift >= 0 {
    let part = (bit_length >> shift).to_uint() & 0xffU
    padded.push(part)
    shift = shift - 8
  }
  let state = sha256_initial_state()
  let mut offset = 0
  while offset < padded.length() {
    sha256_compress(state, padded, offset)
    offset = offset + 64
  }
  let digest : Array[UInt] = []
  for word_index in 0..<8 {
    let word = state[word_index]
    digest.push((word >> 24) & 0xffU)
    digest.push((word >> 16) & 0xffU)
    digest.push((word >> 8) & 0xffU)
    digest.push(word & 0xffU)
  }
  digest
}

///|
fn sha256_compress(
  state : FixedArray[UInt],
  data : Array[UInt],
  offset : Int,
) -> Unit {
  let w : FixedArray[UInt] = FixedArray::make(64, 0U)
  for index in 0..<16 {
    let base = offset + index * 4
    w[index] = (data[base] << 24) |
      (data[base + 1] << 16) |
      (data[base + 2] << 8) |
      data[base + 3]
  }
  for index in 16..<64 {
    let s0 = sha256_small_sigma0(w[index - 15])
    let s1 = sha256_small_sigma1(w[index - 2])
    w[index] = w[index - 16] + s0 + w[index - 7] + s1
  }
  let mut a = state[0]
  let mut b = state[1]
  let mut c = state[2]
  let mut d = state[3]
  let mut e = state[4]
  let mut f = state[5]
  let mut g = state[6]
  let mut h = state[7]
  for round in 0..<64 {
    let temp1 = h +
      sha256_big_sigma1(e) +
      sha256_ch(e, f, g) +
      sha256_k[round] +
      w[round]
    let temp2 = sha256_big_sigma0(a) + sha256_maj(a, b, c)
    h = g
    g = f
    f = e
    e = d + temp1
    d = c
    c = b
    b = a
    a = temp1 + temp2
  }
  state[0] = state[0] + a
  state[1] = state[1] + b
  state[2] = state[2] + c
  state[3] = state[3] + d
  state[4] = state[4] + e
  state[5] = state[5] + f
  state[6] = state[6] + g
  state[7] = state[7] + h
}

///|
/// Computes the SHA-256 digest of the UTF-8 encoded `message` and
/// returns the lowercase hex string.
pub fn sha256_hex(message : String) -> String {
  hex_encode_bytes(sha256_bytes(utf8_bytes(message)))
}

///|
/// HMAC-SHA-256 keyed message authentication (RFC 2104).
///
/// `key` and `message` are arbitrary byte sequences. The returned tag is
/// a 32-byte array represented as `Array[UInt]` (each element in 0..255).
pub fn hmac_sha256_bytes(
  key : Array[UInt],
  message : Array[UInt],
) -> Array[UInt] {
  let block_size = 64
  let prepared_key : Array[UInt] = []
  if key.length() > block_size {
    let hashed = sha256_bytes(key)
    for value in hashed {
      prepared_key.push(value)
    }
  } else {
    for value in key {
      prepared_key.push(value)
    }
  }
  while prepared_key.length() < block_size {
    prepared_key.push(0U)
  }
  let inner_pad : Array[UInt] = []
  let outer_pad : Array[UInt] = []
  for value in prepared_key {
    inner_pad.push(value ^ 0x36U)
    outer_pad.push(value ^ 0x5cU)
  }
  let inner = sha256_bytes(concat_bytes(inner_pad, message))
  sha256_bytes(concat_bytes(outer_pad, inner))
}

///|
/// Convenience wrapper for HMAC-SHA-256 over UTF-8 encoded strings.
/// Returns the 32-byte tag as a lowercase hex string.
pub fn hmac_sha256_hex(key : String, message : String) -> String {
  hex_encode_bytes(hmac_sha256_bytes(utf8_bytes(key), utf8_bytes(message)))
}
