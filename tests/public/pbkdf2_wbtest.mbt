///|
test "pbkdf2_hmac_sha256_hex matches RFC 6070 vector 1 (1 iteration)" {
  // password="password", salt="salt", c=1, dkLen=32
  // expected = 120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b
  assert_eq(
    pbkdf2_hmac_sha256_hex("password", "salt", 1, 32),
    "120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b",
  )
}

///|
test "pbkdf2_hmac_sha256_hex matches RFC 6070 vector 2 (2 iterations)" {
  // password="password", salt="salt", c=2, dkLen=32
  // expected = ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43
  assert_eq(
    pbkdf2_hmac_sha256_hex("password", "salt", 2, 32),
    "ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43",
  )
}

///|
test "pbkdf2_hmac_sha256_hex matches RFC 6070 vector 3 (4096 iterations)" {
  // password="password", salt="salt", c=4096, dkLen=32
  // expected = c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a
  assert_eq(
    pbkdf2_hmac_sha256_hex("password", "salt", 4096, 32),
    "c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a",
  )
}

///|
test "pbkdf2_hmac_sha256 handles dk_len that is not a multiple of 32" {
  // password="passwordPASSWORDpassword", salt="saltSALTsaltSALTsaltSALTsaltSALTsalt", c=4096, dkLen=40
  // expected = 348c89dbcbd32b2f32d814b8116e84cf2b17347ebc1800181c4e2a1fb8dd53e1c635518c7dac47e9
  let tag = pbkdf2_hmac_sha256_hex(
    "passwordPASSWORDpassword", "saltSALTsaltSALTsaltSALTsaltSALTsalt", 4096, 40,
  )
  assert_eq(
    tag, "348c89dbcbd32b2f32d814b8116e84cf2b17347ebc1800181c4e2a1fb8dd53e1c635518c7dac47e9",
  )
}

///|
test "digest_password_secure round-trips verify_password_secure" {
  let digest = digest_password_secure("hunter2", "user-7-salt", iterations=1000)
  assert_true(digest.has_prefix("pbkdf2$sha256$1000$"))
  assert_true(verify_password_secure("hunter2", digest))
  assert_false(verify_password_secure("hunter3", digest))
  assert_false(verify_password_secure("", digest))
}

///|
test "verify_password_secure rejects malformed digests" {
  assert_false(verify_password_secure("hunter2", ""))
  assert_false(verify_password_secure("hunter2", "not-a-digest"))
  assert_false(
    verify_password_secure("hunter2", "pbkdf2$sha512$1000$abcd$efgh"),
  )
  assert_false(verify_password_secure("hunter2", "pbkdf2$sha256$abc$abcd$efgh"))
  assert_false(verify_password_secure("hunter2", "pbkdf2$sha256$1000$zz$ef"))
}

///|
test "hex_decode_bytes round-trips through hex_encode_bytes" {
  let bytes : Array[UInt] = [0x00U, 0xffU, 0x10U, 0x7fU, 0x80U]
  let encoded = hex_encode_bytes(bytes)
  match hex_decode_bytes(encoded) {
    Some(decoded) => {
      assert_eq(decoded.length(), bytes.length())
      assert_eq(decoded[0], 0x00U)
      assert_eq(decoded[1], 0xffU)
      assert_eq(decoded[2], 0x10U)
      assert_eq(decoded[3], 0x7fU)
      assert_eq(decoded[4], 0x80U)
    }
    None => assert_true(false)
  }
  // Bad cases.
  assert_true(hex_decode_bytes("abc") is None)
  assert_true(hex_decode_bytes("zz") is None)
}
