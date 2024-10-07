## routes - application-specific routes
##
## HTTP.sh supports both serving files using a directory structure (webroot),
## and using routes. The latter may come in handy if you want to create nicer
## paths, e.g.
##
## (webroot) https://example.com/profile.shs?name=asdf
## ... may become ...
## (routes)  https://example.com/profile/asdf
##
## To set up routes, define rules in this file (see below for examples)

# router "/test" "app/views/test.shs"
# router "/profile/:user" "app/views/user.shs"
