///|
/// Builds the `Note` model used by the resource app example.
fn note_model() -> @mbor.ModelSchema {
  @mbor.model(
    "Note",
    "notes",
    [
      @mbor.string_column("title"),
      @mbor.text_column("body"),
      @mbor.string_column("slug").indexed(),
    ],
    true,
    false,
  )
  .with_validation(@mbor.validates_presence("title"))
  .with_validation(@mbor.validates_length_min("body", 10))
}
