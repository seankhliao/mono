// Base64url encode / decode, used by webauthn https://www.w3.org/TR/webauthn-2/
function bufferEncode(value) {
  return btoa(String.fromCharCode.apply(null, new Uint8Array(value)))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=/g, "");
}
function bufferDecode(value) {
  return Uint8Array.from(
    atob(value.replace(/-/g, "+").replace(/_/g, "/")),
    (c) => c.charCodeAt(0),
  );
}
// login
async function loginUser() {
  const startResponse = await fetch("/login/start", {
    method: "POST",
  });
  if (!startResponse.ok) {
    alert("failed to start");
    return;
  }
  let opts = await startResponse.json();
  opts.publicKey.challenge = bufferDecode(opts.publicKey.challenge);
  if (opts.publicKey.allowCredentials) {
    opts.publicKey.allowCredentials.forEach(
      (it) => (it.id = bufferDecode(it.id)),
    );
  }
  const assertion = await navigator.credentials.get({
    publicKey: opts.publicKey,
  });

  const finishResponse = await fetch("/login/finish", {
    method: "POST",
    body: JSON.stringify({
      id: assertion.id,
      rawId: bufferEncode(assertion.rawId),
      type: assertion.type,
      response: {
        authenticatorData: bufferEncode(assertion.response.authenticatorData),
        clientDataJSON: bufferEncode(assertion.response.clientDataJSON),
        signature: bufferEncode(assertion.response.signature),
        userHandle: bufferEncode(assertion.response.userHandle),
      },
    }),
  });
  if (!finishResponse.ok) {
    alert("failed to login");
    return;
  }
  window.location.reload();
}
// register
async function registerUser() {
  let email = encodeURIComponent(document.querySelector("#email").value);
  let adminKey = document.querySelector("#adminkey").value;
  let params = new URLSearchParams({ adminkey: adminKey });

  const startResponse = await fetch(`/register/${email}/start?${params}`, {
    method: "POST",
  });
  if (!startResponse.ok) {
    alert("failed to start");
  }
  let opts = await startResponse.json();
  opts.publicKey.challenge = bufferDecode(opts.publicKey.challenge);
  opts.publicKey.user.id = bufferDecode(opts.publicKey.user.id);
  if (opts.publicKey.excludeCredentials) {
    opts.publicKey.excludeCredentials.forEach(
      (it) => (it.id = bufferDecode(it.id)),
    );
  }
  const cred = await navigator.credentials.create({
    publicKey: opts.publicKey,
  });
  const finishResponse = await fetch(`/register/${email}/finish?${params}`, {
    method: "POST",
    body: JSON.stringify({
      id: cred.id,
      rawId: bufferEncode(cred.rawId),
      type: cred.type,
      response: {
        attestationObject: bufferEncode(cred.response.attestationObject),
        clientDataJSON: bufferEncode(cred.response.clientDataJSON),
      },
    }),
  });
  if (!finishResponse.ok) {
    alert("failed to register");
    return;
  }
  window.location.href = "/";
}
