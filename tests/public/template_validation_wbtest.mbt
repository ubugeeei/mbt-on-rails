///|
test "template validator requires explicit component imports" {
  let source = "<script setup>\n" +
    "import {\n" +
    "  component LikeButton,\n" +
    "  component PostHero,\n" +
    "}\n" +
    "</script>\n" +
    "<template>\n" +
    "  <section>\n" +
    "    <PostHero server:defer />\n" +
    "    <LikeButton client:load />\n" +
    "  </section>\n" +
    "</template>\n"

  assert_eq(template_component_imports(source), ["LikeButton", "PostHero"])
  assert_eq(template_component_usages(source), ["PostHero", "LikeButton"])
  assert_eq(validate_template_component_imports("demo.mbtv", source), [])
}

///|
test "template validator reports missing and unused imports" {
  let source = "<script setup>\n" +
    "import {\n" +
    "  component LikeButton,\n" +
    "  component PostHero,\n" +
    "}\n" +
    "</script>\n" +
    "<template>\n" +
    "  <section>\n" +
    "    <LikeButton client:load />\n" +
    "  </section>\n" +
    "</template>\n"

  let errors = validate_template_component_imports("demo.mbtv", source)
  assert_true(errors.contains("demo.mbtv: unused component import PostHero"))
  assert_false(
    errors.contains("demo.mbtv: missing component import for <LikeButton>"),
  )
}
