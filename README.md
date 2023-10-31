# SSCCE: ANSI escape codes are present in ErrorPage.Internal at run-time, in the browser

Because the dev server does not let the `ErrorPage` get shown, this reproduction instead console.logs the errant value (via `Pages.Script.log`). Otherwise I, AFAIK, this would need to be deployed just to reproduce the problem.

First start up the dev server:

    npm install
    npx elm-pages dev


Then load localhost:1234/foobar in browser. You'll notice the following console output from the
`Route.Foobar.data` function:

```json
{
    "onError fatal": "FatalError { body = \"\u001bCouldn't find file at path `\u001b[0m\u001b[33mfile-that-does-not-exist\u001b[0m\u001b`\u001b[0m\", title = \"File Doesn't Exist\" }",
    "--": "When deployed, the *exact* same fatal.body string is given to ErrorPage, wrapped in ErrorPage.InternalError"
}

```

Which shows ANSI escape codes in the `FatalError` body string.

See [Route.Foobar.data](./app/Route/Foobar.elm#L98)
