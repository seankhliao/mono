<!DOCTYPE html>
<html lang="en">
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,minimum-scale=1,initial-scale=1">
  <title>{{ if .Title }}{{ .Title }}{{ else }}seankhliao{{ end }}</title>

  {{ .Head }}

  {{ with .GTM }}
  <!-- Google tag (gtag.js) -->
  <script async src="https://www.googletagmanager.com/gtag/js?id={{ . }}"></script>
  <script>
    window.dataLayer = window.dataLayer || [];
    function gtag(){dataLayer.push(arguments);}
    gtag('js', new Date());

    gtag('config', '{{ . }}');
  </script>
  {{ end }}

  {{ with .URL }}<link rel="canonical" href="{{ . }}">{{ end }}
  <link rel="manifest" href="/manifest.json">

  <meta name="theme-color" content="#000000">
  {{ with .Desc }}<meta name="description" content="{{ . }}">{{ end }}

  <link rel="icon" href="https://seankhliao.com/favicon.ico">
  <link rel="icon" href="https://seankhliao.com/static/icon.svg" type="image/svg+xml" sizes="any">
  <link rel="apple-touch-icon" href="https://seankhliao.com/static/icon-192.png">

  <style>
    {{ template "basecss" . }}
    {{ .Style }}

    .chroma {
      position: relative;
    }
    .chroma > button {
      position: absolute;
      top: 0;
      right: 0;
      color: var(--primary);
      background: #000;
      border: 1px solid var(--primary);
      padding: 1em;
      width: 5em;
    }
  </style>

  <h1>{{ .Title }}</h1>
  {{ with .Subtitle }}<h2>{{ . }}</h2>{{ end }}

  <hgroup>
    <a href="https://seankhliao.com/">
      <span>S</span><span>E</span><span>A</span><span>N</span>
      <em>K</em><em>.</em><em>H</em><em>.</em>
      <span>L</span><span>I</span><span>A</span><span>O</span>
    </a>
  </hgroup>

  {{ .Main }}

  <footer>
    <a href="https://seankhliao.com/">home</a>
    |
    <a href="https://seankhliao.com/blog/">blog</a>
    |
    <a href="https://sean.liao.dev/">elsewhere</a>
  </footer>

  <script>
  // click headers updates url bar
  document.querySelectorAll('h3,h4,h5,h6').forEach((node) => {
    n.addEventListener('click', (event) => {
      document.location.hash = node.id;

      gtag('event', 'header_link_click', {
        'location': window.location.href,
        'header_id': node.id,
      });
    });
  });

  // copy button on code blocks
  document.querySelectorAll(".chroma").forEach((block) => {
    if (!navigator.clipboard) {
      return;
    }

    let button = document.createElement("button");
    button.innerText = "Copy";
    block.appendChild(button);

    button.addEventListener("click", async () => {
      let codeText = [...block.querySelectorAll('.cl')].map((n) => n.innerText).join("")
      await navigator.clipboard.writeText(codeText);
      button.innerText = "Copied";
      setTimeout(() => {
        button.innerText = "Copy";
      }, 2000);

      gtag('event', 'code_block_copy', {
        'location': window.location.href,
        'block_id': block.querySelector('.ln').id.split('-')[0],
      });
    });
  });
  </script>
</html>
