///|
test "sha256_hex matches FIPS 180-4 known-answer test vectors" {
  // SHA-256("") = e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
  assert_eq(
    sha256_hex(""),
    "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
  )
  // SHA-256("abc") = ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad
  assert_eq(
    sha256_hex("abc"),
    "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad",
  )
  // SHA-256("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq") =
  //   248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1
  assert_eq(
    sha256_hex("abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq"),
    "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1",
  )
}

///|
test "hmac_sha256_hex matches RFC 4231 Test Case 1" {
  // key   = 0x0b * 20
  // data  = "Hi There"
  // hmac  = b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7
  let key : Array[UInt] = []
  for _ in 0..<20 {
    key.push(0x0bU)
  }
  let data = utf8_bytes("Hi There")
  let tag = hmac_sha256_bytes(key, data)
  assert_eq(
    hex_encode_bytes(tag),
    "b0344c61d8db38535ca8afceaf0bf12b881dc200c9833da726e9376c2e32cff7",
  )
}

///|
test "hmac_sha256_hex matches RFC 4231 Test Case 2" {
  // key  = "Jefe"
  // data = "what do ya want for nothing?"
  // hmac = 5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843
  assert_eq(
    hmac_sha256_hex("Jefe", "what do ya want for nothing?"),
    "5bdcc146bf60754e6a042426089575c75a003f089d2739839dec58b964ec3843",
  )
}

///|
test "hmac_sha256_hex hashes long keys before signing" {
  // key = 0xaa * 131 (>64 bytes triggers key=SHA256(key))
  // data = "Test Using Larger Than Block-Size Key - Hash Key First"
  // hmac = 60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54
  let key : Array[UInt] = []
  for _ in 0..<131 {
    key.push(0xaaU)
  }
  let data = utf8_bytes(
    "Test Using Larger Than Block-Size Key - Hash Key First",
  )
  let tag = hmac_sha256_bytes(key, data)
  assert_eq(
    hex_encode_bytes(tag),
    "60e431591ee0b67f0d8a26aacbf5b77f8e0bc6213728c5140546040f0ee37f54",
  )
}

///|
test "utf8_bytes encodes ASCII and multibyte characters" {
  let ascii = utf8_bytes("abc")
  assert_eq(ascii.length(), 3)
  assert_eq(ascii[0], 0x61U)
  assert_eq(ascii[1], 0x62U)
  assert_eq(ascii[2], 0x63U)
  let multibyte = utf8_bytes("\u{00a3}")
  assert_eq(multibyte.length(), 2)
  assert_eq(multibyte[0], 0xc2U)
  assert_eq(multibyte[1], 0xa3U)
}

///|
test "sign_cookie_value now produces an HMAC-SHA-256 tag" {
  let signed = sign_cookie_value("session", "user-42", "secret-key-base")
  match verify_signed_cookie_value("session", signed, "secret-key-base") {
    Some(value) => assert_eq(value, "user-42")
    None => assert_true(false)
  }
  // The tag portion is 64 lowercase hex characters.
  let parts_index = signed.length() - 64
  let tag = signed[parts_index:].to_string()
  assert_eq(tag.length(), 64)
  for ch in tag {
    let allowed = (ch >= '0' && ch <= '9') || (ch >= 'a' && ch <= 'f')
    assert_true(allowed)
  }
}
