<!DOCTYPE html>
<html lang="en">
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,minimum-scale=1,initial-scale=1">
  <title>{{ if .Title }}{{ .Title }}{{ else }}seankhliao{{ end }}</title>

  {{ .Head }}

  {{ with .GTM }}
  <script>
    (function (w, d, s, l, i) {
      w[l] = w[l] || []; w[l].push({ "gtm.start": new Date().getTime(), event: "gtm.js" });
      var f = d.getElementsByTagName(s)[0], j = d.createElement(s), dl = l != "dataLayer" ? "&l=" + l : "";
      j.async = true; j.src = "https://www.googletagmanager.com/gtm.js?id=" + i + dl;
      f.parentNode.insertBefore(j, f);
    })(window, document, "script", "dataLayer", "{{ . }}");
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
  </style>

  {{ with .GTM }}<noscript><iframe src="https://www.googletagmanager.com/ns.html?id={{ . }}" height="0" width="0" style="display: none; visibility: hidden"></iframe></noscript>{{ end }}

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
    <a href="https://github.com/seankhliao">github</a>
  </footer>
</html>
