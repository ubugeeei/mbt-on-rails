///|
/// Builds the `Note` model used by the resource app example.
fn note_model() -> @mbor.ModelSchema {
  @mbor.with_validation(
    @mbor.with_validation(
      @mbor.model(
        "Note",
        "notes",
        [
          @mbor.string_column("title"),
          @mbor.text_column("body"),
          @mbor.indexed(@mbor.string_column("slug")),
        ],
        true,
        false,
      ),
      @mbor.validates_presence("title"),
    ),
    @mbor.validates_length_min("body", 10),
  )
}
