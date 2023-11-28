document.querySelectorAll("h3,h4,h5,h6").forEach((node) => {
  n.addEventListener("click", (event) => {
    document.location.hash = node.id;

    gtag("event", "header_link_click", {
      location: window.location.href,
      header_id: node.id,
    });
  });
});
