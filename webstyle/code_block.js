document.querySelectorAll(".chroma").forEach((block) => {
  if (!navigator.clipboard) {
    return;
  }

  let button = document.createElement("button");
  button.innerText = "Copy";
  block.appendChild(button);

  button.addEventListener("click", async () => {
    let codeText = [...block.querySelectorAll(".cl")]
      .map((n) => n.innerText)
      .join("");
    await navigator.clipboard.writeText(codeText);
    button.innerText = "Copied";
    setTimeout(() => {
      button.innerText = "Copy";
    }, 2000);

    gtag("event", "code_block_copy", {
      location: window.location.href,
      block_id: block.querySelector(".ln").id.split("-")[0],
    });
  });
});
