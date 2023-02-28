## untangleable-json
Creates Untangle compatible .json for the webfilter and adblocker app, or fails miserably.

Work in progress:
* Find similar subdomains and make a single entry out of them

```
As has been discussed on the Untangle forums, loading the webfilter app full of domains is stupid. This is first and foremost a way for me to learn more about regex in a fun way.
```

## Untangle syntax
https://wiki.edge.arista.com/index.php/URL_Matcher
https://wiki.edge.arista.com/index.php/Glob_Matcher

```
* The left side of the rule is anchored with the regular expression "^([a-zA-Z_0-9-]*\.)*". "foo.com" will match only "foo.com" and "abc.foo.com" but not "afoo.com"

* The right side of the rule is anchored with with the regular expression ".*$". "foo.com" will match "foo.com/test.html" because it is actually "foo.com.*$". "foo.com/bar" is "foo.com/bar.*$" which will match "foo.com/bar/baz" and "foo.com/bar2". Also "foo" becomes "foo.*" which will match "foobar.com" and "foo.com"
```