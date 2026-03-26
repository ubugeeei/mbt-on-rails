///|
priv struct UtcTimestamp {
  year : Int
  month : Int
  day : Int
  hour : Int
  minute : Int
  second : Int
}

///|
fn parse_utc_timestamp(source : String) -> UtcTimestamp? {
  if source.length() != 20 {
    return None
  }
  if not(
      unsafe_char_at(source, 4) == '-' &&
      unsafe_char_at(source, 7) == '-' &&
      unsafe_char_at(source, 10) == 'T' &&
      unsafe_char_at(source, 13) == ':' &&
      unsafe_char_at(source, 16) == ':' &&
      unsafe_char_at(source, 19) == 'Z',
    ) {
    return None
  }
  match parse_int_slice(source, 0, 4) {
    Some(year) =>
      match parse_int_slice(source, 5, 7) {
        Some(month) =>
          match parse_int_slice(source, 8, 10) {
            Some(day) =>
              match parse_int_slice(source, 11, 13) {
                Some(hour) =>
                  match parse_int_slice(source, 14, 16) {
                    Some(minute) =>
                      match parse_int_slice(source, 17, 19) {
                        Some(second) =>
                          Some({ year, month, day, hour, minute, second })
                        None => None
                      }
                    None => None
                  }
                None => None
              }
            None => None
          }
        None => None
      }
    None => None
  }
}

///|
fn parse_int_slice(source : String, start : Int, end : Int) -> Int? {
  let mut value = 0
  let mut index = start
  while index < end {
    let ch = unsafe_char_at(source, index)
    if ch < '0' || ch > '9' {
      return None
    }
    value = value * 10 + (ch.to_int() - '0'.to_int())
    index += 1
  }
  Some(value)
}

///|
fn add_seconds(timestamp : UtcTimestamp, extra_seconds : Int) -> UtcTimestamp {
  let mut year = timestamp.year
  let mut month = timestamp.month
  let mut day = timestamp.day
  let mut hour = timestamp.hour
  let mut minute = timestamp.minute
  let mut second = timestamp.second + extra_seconds

  minute += second / 60
  second = second % 60

  hour += minute / 60
  minute = minute % 60

  day += hour / 24
  hour = hour % 24

  while day > days_in_month(year, month) {
    day -= days_in_month(year, month)
    month += 1
    if month > 12 {
      month = 1
      year += 1
    }
  }

  { year, month, day, hour, minute, second }
}

///|
fn days_in_month(year : Int, month : Int) -> Int {
  match month {
    1 => 31
    2 => if is_leap_year(year) { 29 } else { 28 }
    3 => 31
    4 => 30
    5 => 31
    6 => 30
    7 => 31
    8 => 31
    9 => 30
    10 => 31
    11 => 30
    _ => 31
  }
}

///|
fn is_leap_year(year : Int) -> Bool {
  if year % 400 == 0 {
    return true
  }
  if year % 100 == 0 {
    return false
  }
  year % 4 == 0
}

///|
fn format_utc_timestamp(timestamp : UtcTimestamp) -> String {
  timestamp.year.to_string() +
  "-" +
  pad_two(timestamp.month) +
  "-" +
  pad_two(timestamp.day) +
  "T" +
  pad_two(timestamp.hour) +
  ":" +
  pad_two(timestamp.minute) +
  ":" +
  pad_two(timestamp.second) +
  "Z"
}

///|
fn pad_two(value : Int) -> String {
  if value < 10 {
    "0" + value.to_string()
  } else {
    value.to_string()
  }
}

///|
fn unsafe_char_at(source : String, index : Int) -> Char {
  source.unsafe_get(index).unsafe_to_char()
}
