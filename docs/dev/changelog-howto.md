# CHANGELOG syntax

To make sure that http.sh can display the changelog and warn the developers about
potential breaking changes, we need to adhere to a very specific schema:

```
v(version)
---

Description: Lorem ipsum dolor sit amet (optional)

BREAKING:
- g
- h

New:
- a
- b

Fixed:
- c
- d

Misc:
- e
- f


```

Important:
- one empty line after each subsection
- two empty lines after each version entry
- wrap lines at around 100 characters (roughly half of dmi's screen in Monaspace Krypton 13)
- for multiline points, add padding spaces to make them look nice (like above)
- subsection names aren't set in stone, except for BREAKING, which should be written exactly
  as above, for parsing reasons.
- subsections can never have empty lines between objects
