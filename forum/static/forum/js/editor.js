// Replaces marked textareas with Quill; server still sanitizes the HTML
document.querySelectorAll("textarea[data-editor]").forEach((textarea) => {
  const container = document.createElement("div");
  textarea.after(container);
  textarea.hidden = true;
  const quill = new Quill(container, {
    theme: "snow",
    modules: {
      toolbar: [
        ["bold", "italic", "underline", "strike"],
        ["link", "blockquote", "code-block"],
        [{ list: "ordered" }, { list: "bullet" }],
      ],
    },
  });
  // Set through CSSOM, so CSP (no inline styles) doesn't block it
  quill.root.style.minHeight = "10rem";
  quill.setContents(quill.clipboard.convert({ html: textarea.value }));
  textarea.form.addEventListener("submit", () => {
    // Quill 2.0.3 turns every space into &nbsp;, which stops long lines from wrapping
    textarea.value = quill.getSemanticHTML().replaceAll("&nbsp;", " ");
  });
});
