# Dropbox

## Remove all shared links

Go to <https://www.dropbox.com/share/links>, open the browser's JavaScript console (⌘ + ⎇ + I) and paste the following:

```js
$$("#links-list .mc-popover-trigger").forEach((n) => {
  console.log("delete", n);
  n.click();
  $(".delete-link").click();
  $(".button-primary").click();
});
```
