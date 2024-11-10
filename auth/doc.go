// auth implements a user authentication / authorization server.
//
// The only available user authentication method is passkeys (resident keys).
// User registration is achieved by obtaining an admin token from the debug endpoint
// :8081/debug/admin-token and registering with new credentials.
//
// The [App.AuthN] middleware will ensure all requests have an associated session,
// identified by a [authv1.TokenInfo] which can be obtained from the request context
// with [FromContext].
//
// The [App.AuthZ] middleware will ensure all requests conform to the given policy.
// By default, 2 policies are available,
// [AllowAnonymous] allows all requests through,
// [AllowRegistered] only allows requests from users with registered accounts.
//
// Sessions are handled with cookies and cleared on a schedule,
// 6 hours for anonymous sessions and 1 week for registered users.
package auth
